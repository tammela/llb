--
-- Lua binding for LLVM C API.
-- Copyright (C) 2018 Matheus Ambrozio, Pedro Tammela, Renan Almeida.
--
-- This file is part of llb.
--
-- llb is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
--
-- llb is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with llb. If not, see <http://www.gnu.org/licenses/>.
--

local set = require "set"

local bbgraph = {}
bbgraph.__index = bbgraph

--
-- receives a list of basic blocks
-- returns the predecessors-sucessors graph for the basic blocks
--
function bbgraph.new(bbs)
    local nodes = {}
    setmetatable(nodes, bbgraph)

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

--
-- dominators
-- returns {node: set<node>}
-- dom[a] = {a, b, c} ===> "a", b" and "c" dominate "a"
--
function bbgraph:dom()
    local all = set.new(table.unpack(self))
    local entry = self[1] -- TODO: is the entry bb always bbgraph[1]?
    local regular_nodes = all - {entry}
    local dom = {}

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

--
-- strict dominance
-- returns {node: set<node>}
-- dom[a] = {b, c} ===> b" and "c" strictly dominate "a"
--
function bbgraph:sdom(dom)
    local sdom
    if dom ~= nil then
        sdom = {}
        for k, v in pairs(dom) do
            sdom[k] = v:copy()
            sdom[k]:remove(k)
        end
    else
        sdom = self:dom()
        for k, v in pairs(sdom) do
            v:remove(k)
        end
    end
    return sdom
end

--
-- imediate dominance
-- returns {node: node}
-- TODO
--
function bbgraph:idom(dom)
    local dom = dom or self:dom()

    local all = set.new(table.unpack(self))
    local entry = self[1] -- entry basic block is always bbgraph[1]
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

--
-- reverse idom
-- returns {node: set<node>}
-- TODO
--
function bbgraph:ridom(idom)
    local idom = idom or self:idom()
    local ridom = {}

    for _, v in ipairs(self) do
        ridom[v] = set.new()
    end

    for k, v in pairs(idom) do
        ridom[v]:add(k)
    end

    return ridom
end

--
-- dominance frontier (FIXME: this is the quadratic version)
-- TODO
--
function bbgraph:df(dom, sdom)
    local dom = dom or self:dom()
    local sdom = sdom or self:sdom(dom)

    local df = {}

    for _, x in ipairs(self) do
        df[x] = set.new()
    end

    -- df(x) = {y | (z E predecessors(y) | x C dom[z]) and (x !C sdom[y])}
    for _, x in ipairs(self) do
        for _, y in ipairs(self) do
            for z in pairs(y.predecessors) do
                if dom[z]:contains(x) and not sdom[y]:contains(x) then
                    df[x]:add(y)
                end
            end
        end
    end

    return df
end

--
-- computes the iterated dominance frontier (DF+) of nodes in S
-- "if S is the set of nodes that assign to variable x then DF+(S) is exactly
-- the set of nodes that need phi-functions for x"
--
function bbgraph:dfplus(s, df)
    local df = df or self:df()

    local s = s:copy()
    s:add(self[1]) -- adds "entry" block

    local function dfunion(s)
        local dfu = set.new()
        for x in pairs(s) do
            dfu = dfu + df[x]
        end
        return dfu
    end

    -- S = bbgraph
    -- DF(S) = U[x E S] DF(x)
    local dfs = dfunion(s)

    -- DF[1](S) = DF(S)
    -- DF[i+1](S) = DF(S U DF[i](S))
    -- DF+(S) = lim[i => infinity] DF[i](S)
    local dfp = dfs
    repeat
        local change = false
        local D = dfunion(s + dfp)
        if D ~= dfp then
            dfp = D
            change = true
        end
    until not change

    return dfp
end

--
-- returns set<{[block], [ref], [usages], [stores]}>
-- for all instructions in a bb graph
--
function bbgraph:map_instructions()
    local instructions, aux = set.new(), {}
    for _, block in ipairs(self) do
        for _, reference in ipairs(block.ref:instructions()) do
            local instruction = {
                block = block,
                ref = reference,
                usages = set.new(),
                stores = set.new(),
            }
            instructions:add(instruction)
            aux[reference:pointer()] = instruction
        end
    end
    for instruction in pairs(instructions) do
        for _, usage in ipairs(instruction.ref:usages()) do
            local usage_instruction = aux[usage]
            instruction.usages:add(usage_instruction)
            if usage_instruction.ref:is_store() then
                instruction.stores:add(usage_instruction)
            end
        end
    end
    return instructions
end

--
-- __tostring metamethod
-- returns a human readable basic block graph
--
function bbgraph:__tostring()
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

return bbgraph
