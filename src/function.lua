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
    local regularnodes = all - {entry}
    local dom = {} -- {node: set<node>}

    dom[entry] = set.new(entry)
    for n in pairs(regularnodes) do
        dom[n] = all
    end

    repeat
        local change = false
        for n in pairs(regularnodes) do
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
    local regularnodes = all - {entry}
    local idom = {}

    for n in pairs(regularnodes) do
        idom[n] = dom[n] - {n}
    end

    for n in pairs(regularnodes) do
        for s in pairs(idom[n]) do
            for t in pairs(idom[n] - {s}) do
                if idom[s]:contains(t) then
                    idom[n] = idom[n] - {t}
                end
            end
        end
    end

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
            auxmap[inst:pointer()] = all_instructions[i]
            i = i + 1
        end
    end

    -- mapping usages. where the result of the instruction is used as an argument
    for _, inst in ipairs(all_instructions) do
        for _, u in ipairs(inst.ref:usages()) do
            local usage = auxmap[u]
            table.insert(inst.usages, usage)
        end
    end

    return all_instructions
end

-- puts the IR in true SSA form (withot useless alloca/store/load instructions)
function fn:ssa(bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    -- TODO
    return bbgraph
end

return fn
