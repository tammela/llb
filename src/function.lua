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

-- computes the dominance tree of a function
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

    return idom
end

function fn:map_instructions(bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    local all_instructions = {}
    local auxmap = {}

    -- getting all instructions
    local i = 1
    for _, bb in ipairs(bbgraph) do
        for _, inst in ipairs(bb.ref:instructions()) do
            all_instructions[inst] = {
                id = i,
                bb = bb,
                ref = inst,
                usages = {}
            }
            auxmap[inst:pointer()] = all_instructions[inst]
            i = i + 1
        end
    end

    -- mapping usages.
    -- where the result of the instruction is used as an argument
    for _, inst in pairs(all_instructions) do
        for _, u in ipairs(inst.ref:usages()) do
            local usage = auxmap[u]
            table.insert(inst.usages, usage)
        end
    end

    return all_instructions
end

local function ridom(idomtree)
    local r = {}
    for node, dominated in pairs(idomtree) do
        if r[node] == nil then
            r[node] = {}
        end
        for d in pairs(dominated) do
            if r[d] == nil then
                r[d] = {}
            end
            table.insert(r[d], node)
        end
    end

    print('----------------ridom')
    for k, v in pairs(r) do
        print('->', k.ref)
        for i, j in pairs(v) do
            print('-->', j.ref)
        end
    end
    print('----------------ridom')

    return r
end

local function append(t, ...)
    for _, v in pairs(...) do
        table.insert(t, v)
    end
end

local function idom_post_order_traversal(node, ridom)
    local t = {}
    print('->', #ridom[node], node.ref)
    if #ridom[node] == 0 then
        print('returning')
        return {node}
    end
    print('===', ridom[node][1].ref)
    for _, successor in pairs(ridom[node]) do
        local x0 = idom_post_order_traversal(successor, ridom)
        append(t, table.unpack(x0))
    end
    return t
end

function fn:dominance_frontier()
    local bbgraph = bbgraph or self:bbgraph()
    local idom = self:idomtree(bbgraph)
    local ridom = ridom(idom)

    -- IDom, Succ, Pred:  Node — > set of Node
    --
    -- procedure Dom_Front(N,E,r)  returns Node — > set of Node
    --     N: in set of Node
    --     E: in set of  (Node x Node)
    --     r: in Node
    -- begin
    --     y, z:  Node
    --     P: sequence of Node
    --     i:  integer
    --     DF:  Node -> set of Node
    --     Domin.Fast(N,r,IDom)
    --     P  := Post_Order(N,IDom)
    --     for i  := 1 to  IPI  do
    --         DF(Pli) := 0
    --         ||  compute local component
    --         for each y e Succ(Pli)  do
    --             if y !E IDom(Pli) then
    --                 DF(Pli) u= {y}
    --             fi
    --         od
    --         ||  add on up component
    --         for each z e IDom(Pli) do
    --             for each y e DF(z) do
    --                 if y £ IDom(Pli) then
    --                     DF(Pli) u= {y}
    --                 fi
    --             od
    --         od
    --     od
    --     return DF
    -- end    I|  Dom_Front

    return idom_post_order_traversal(bbgraph[1], ridom)
end

-- puts the IR in true SSA form (withot useless alloca/store/load instructions)
function fn:ssa(bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    -- TODO Complete this function

    local all_instructions = self:map_instructions(bbgraph)
    for _, inst in pairs(all_instructions) do
        if inst.ref:is_alloca() then
            print("-> ", inst.ref, inst.ref:is_alloca())
            for k, usage in pairs(inst.usages) do
                print('-->', usage.ref, usage.ref:is_store())
            end
        end
    end

    return bbgraph
end

return fn
