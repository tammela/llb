--
-- Lua binding for LLVM C API.
-- Copyright (C) 2018 Matheus Ambrozio, Pedro Tammela, Renan Almeida.
--
-- This file is part of lua-llvm-binding.
--
-- lua-llvm-binding is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
--
-- lua-llvm-binding is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with lua-llvm-binding. If not, see <http://www.gnu.org/licenses/>.
--

local set = require "set"

local fn = {}

-----------------------------------------------------
--
--  auxiliary
--
-----------------------------------------------------

local graph = {}

function graph.new()
    local t = {}
    setmetatable(t, graph)
    return t
end

function graph:__tostring()
    local nodes = {}
    for _, node in ipairs(self) do
        local t = {}
        table.insert(t, "label: " .. tostring(node.ref))
        table.insert(t, "successors: " .. tostring(node.successors))
        table.insert(t, "predecessors: " .. tostring(node.predecessors))
        table.insert(nodes, table.concat(t, "\n"))
    end
    return "---\n" .. table.concat(nodes, "\n---\n") .. "\n---"
end

-----------------------------------------------------
--
--  functions
--
-----------------------------------------------------

-- computes the predecessors-sucessors graph of a function
function fn:bbgraph()
    local bbs = self:basic_blocks()
    local nodes = graph.new()
    local auxmap = {}

    for i, bb in ipairs(bbs) do
        nodes[i] = {
            ref = bb,
            successors = set.new(),
            predecessors = set.new()
        }
        auxmap[bb:pointer()] = nodes[i]
    end

    for _, node in ipairs(nodes) do
        for _, s in ipairs(node.ref:successors()) do
            local successor = auxmap[s]
            node.successors:add(successor)
            successor.predecessors:add(node)
        end
    end

    return nodes
end

-- computes the dominators of all basic blocks in a function
function fn:domtree(bbgraph)
    local bbgraph = bbgraph or self:bbgraph()

    local all = set.new(table.unpack(bbgraph))
    local entry = bbgraph[1] -- TODO: is the entry bb always bbgraph[1]?
    local regular_nodes = all - {entry}
    local dom = {} -- {node: set<node>}

    dom[entry] = set.new(entry)
    for n in pairs(regular_nodes) do
        dom[n] = all
    end

    repeat
        local change = false
        for n in pairs(regular_nodes) do
            local D = all
            for p in pairs(n.predecessors) do
                D = D * dom[p]
            end
            D = D + {n}
            if D ~= dom[n] then
                change = true
                dom[n] = D
            end
        end
    until not change

    return dom
end

-- computes the strict dominance tree of a function
function fn:sdomtree(bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    local sdom = self:domtree(bbgraph)
    for k, v in pairs(sdom) do
        v:remove(k)
    end
    return sdom
end

-- computes the imediate dominance tree of a function
function fn:idomtree(bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    local dom = self:domtree(bbgraph)

    local all = set.new(table.unpack(bbgraph))
    local entry = bbgraph[1] -- TODO: is the entry bb always bbgraph[1]?
    local regular_nodes = all - {entry}
    local idom = {}

    for n in pairs(all) do
        idom[n] = dom[n] - {n}
    end

    for n in pairs(regular_nodes) do
        for s in pairs(idom[n]) do
            for t in pairs(idom[n] - {s}) do
                if idom[s]:contains(t) then
                    idom[n] = idom[n] - {t}
                end
            end
        end
    end

    idom[entry] = nil

    for k, v in pairs(idom) do
        idom[k] = v:pop()
        assert(v:is_empty())
    end

    return idom
end

-- reverse idomtree
function fn:ridomtree(bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    local idom = self:idomtree(bbgraph)
    local ridom = {}

    for _, v in ipairs(bbgraph) do
        ridom[v] = set.new()
    end

    for k, v in pairs(idom) do
        ridom[v]:add(k)
    end

    return ridom
end

-- computes the dominance frontier of all basic blocks in a function
function fn:df(bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    local dom = self:domtree(bbgraph)
    local sdom = self:sdomtree(bbgraph)
    local df = {}

    -- FIXME: this is the quadratic version

    -- df(x) = {y | (exists z E predecessors(y) | dom[z] contains x) and
    --              (sdom[y] !contains x)}
    
    for _, x in ipairs(bbgraph) do
        df[x] = set.new()
    end

    for _, x in ipairs(bbgraph) do
        for _, y in ipairs(bbgraph) do
            for z in pairs(y.predecessors) do
                if dom[z]:contains(x) and not sdom[y]:contains(x) then
                    df[x]:add(y)
                end
            end
        end
    end

    return df
end

-- function fn:map_instructions(bbgraph)
--     local bbgraph = bbgraph or self:bbgraph()
--     local all_instructions = {}
--     local auxmap = {}

--     -- getting all instructions
--     local i = 1
--     for _, bb in ipairs(bbgraph) do
--         for _, inst in ipairs(bb.ref:instructions()) do
--             all_instructions[inst] = {
--                 id = i,
--                 bb = bb,
--                 ref = inst,
--                 usages = {}
--             }
--             auxmap[inst:pointer()] = all_instructions[inst]
--             i = i + 1
--         end
--     end

--     -- mapping usages.
--     -- where the result of the instruction is used as an argument
--     for _, inst in pairs(all_instructions) do
--         for _, u in ipairs(inst.ref:usages()) do
--             local usage = auxmap[u]
--             table.insert(inst.usages, usage)
--         end
--     end

--     return all_instructions
-- end

-- local function append(t, ...)
--     for _, v in pairs(...) do
--         table.insert(t, v)
--     end
-- end

-- local function idom_post_order_traversal(node, ridom)
--     local t = {}
--     print('->', #ridom[node], node.ref)
--     if #ridom[node] == 0 then
--         print('returning')
--         return {node}
--     end
--     print('===', ridom[node][1].ref)
--     for _, successor in pairs(ridom[node]) do
--         local x0 = idom_post_order_traversal(successor, ridom)
--         append(t, table.unpack(x0))
--     end
--     return t
-- end

-- function fn:dominance_frontier()
--     local bbgraph = bbgraph or self:bbgraph()
--     local idom = self:idomtree(bbgraph)
--     local ridom = ridom(idom)

--     -- IDom, Succ, Pred:  Node — > set of Node
--     --
--     -- procedure Dom_Front(N,E,r)  returns Node — > set of Node
--     --     N: in set of Node
--     --     E: in set of  (Node x Node)
--     --     r: in Node
--     -- begin
--     --     y, z:  Node
--     --     P: sequence of Node
--     --     i:  integer
--     --     DF:  Node -> set of Node
--     --     Domin.Fast(N,r,IDom)
--     --     P  := Post_Order(N,IDom)
--     --     for i  := 1 to  IPI  do
--     --         DF(Pli) := 0
--     --         ||  compute local component
--     --         for each y e Succ(Pli)  do
--     --             if y !E IDom(Pli) then
--     --                 DF(Pli) u= {y}
--     --             fi
--     --         od
--     --         ||  add on up component
--     --         for each z e IDom(Pli) do
--     --             for each y e DF(z) do
--     --                 if y £ IDom(Pli) then
--     --                     DF(Pli) u= {y}
--     --                 fi
--     --             od
--     --         od
--     --     od
--     --     return DF
--     -- end    I|  Dom_Front

--     return idom_post_order_traversal(bbgraph[1], ridom)
-- end

-- -- puts the IR in true SSA form (withot useless alloca/store/load instructions)
-- function fn:ssa(bbgraph)
--     local bbgraph = bbgraph or self:bbgraph()
--     -- TODO Complete this function

--     local all_instructions = self:map_instructions(bbgraph)
--     for _, inst in pairs(all_instructions) do
--         if inst.ref:is_alloca() then
--             print("-> ", inst.ref, inst.ref:is_alloca())
--             for k, usage in pairs(inst.usages) do
--                 print('-->', usage.ref, usage.ref:is_store())
--             end
--         end
--     end

--     return bbgraph
-- end

-----------------------------------------------------
--
--  dominance frontier
--
-----------------------------------------------------

-- local df, dflocal, dfup

-- -- dflocal(x) = {y E successors(x) | ridom(y) != x}
-- local function dflocal(bbgraph, idom)
--     local t = {}
--     for _, x in ipairs(bbgraph) do
--         t[x] = set.new()
--         for y in pairs(x.successors) do
--             if idom[y] ~= x then
--                 t[x]:add(y)
--             end
--         end
--     end
--     return t
-- end

-- -- dfup(x, z) = {y E df(z) | idom(z) == x and idom(y) != x}
-- local function dfup(x, z)
--     local s = set.new()
--     for y in pairs(fn.df(nil, z)) do
--         if idom(z) ~= x and idom(y) ~= x then
--             s:add(y)
--         end
--     end
--     return s
-- end

-- -- df(x) = dflocal(x) union U[z E N (idom(z) == x)] dfup(x, z)
-- local function df(bbgraph, idom, dflocal, x)
--     local U = set.new()
--     for _, z in ipairs(bbgraph) do
--         if idom[z.ref] == x then
--             U = U + dfup(x, z.ref)
--         end
--     end
--     return dflocal[x] + U
-- end

-- function fn:df(bbgraph)
--     local bbgraph = bbgraph or self:bbgraph()
--     local idom = self:idomtree(bbgraph)

--     local dflocal = dflocal(bbgraph, idom)

--     local t = {}
--     for _, x in ipairs(bbgraph) do
--         t[x] = df(bbgraph, idom, dflocal, x)
--     end
--     return t
-- end

return fn
