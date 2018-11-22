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
        table.insert(t, "label: " .. tostring(node.value))
        table.insert(t, "successors: " .. tostring(node.successors))
        table.insert(t, "predecessors: " .. tostring(node.predecessors))
        table.insert(nodes, table.concat(t, "\n"))
    end
    return "---\n" .. table.concat(nodes, "\n---\n") .. "\n---"
end

-----------------------------------------------------
--
--  function
--
-----------------------------------------------------

-- computes the predecessors-sucessors graph of a function
function fn:bbgraph()
    local bbs = self:basic_blocks()
    local nodes = graph.new()
    local auxmap = {}

    for i, bb in ipairs(bbs) do
        nodes[i] = {
            ref = bb, -- TODO ref is a better name than value in my opinion
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

-- computes the dominance graph of a function
function fn:domgraph()
    local bbgraph = self:bbgraph()
    local all = set.new()
    all:add(table.unpack(bbgraph))
    local entry = bbgraph[1] -- TODO is entry bb always bbgraph[1]?

    local D -- set<node>
    local T -- set<node>
    local change = true
    local dom = {} -- {node: set<node>}

    dom[entry] = set.new(entry)
    for n in pairs(all - set.new(entry)) do
        dom[n] = all
    end

    repeat
        change = false
        for n in pairs(all - set.new(entry)) do
            T = all:copy()
            for p in pairs(n.predecessors) do
                T = T * dom[p]
            end
            D = set.new(n) + T
            if D ~= dom[n] then
                change = true
                dom[n] = D
            end
        end
    until not change

    return dom, bbgraph -- necessary to idomgraph. TODO think of a better way
end

-- computes the imediate dominance graph of a function
function fn:idomgraph()
    local dom, bbgraph = self:domgraph() -- getting the same refs
    local all = set.new()
    all:add(table.unpack(bbgraph))

    local entry = bbgraph[1] -- TODO is entry bb always bbgraph[1]?

    local tmp = {}
    local idom = {}

    for n in pairs(all) do
        tmp[n] = dom[n] - set.new(n)
    end

    for n in pairs(all - set.new(entry)) do
        for s in pairs(tmp[n]) do
            for t in pairs(tmp[n] - set.new(s)) do
                if tmp[s]:contains(t) then
                    tmp[n] = tmp[n] - set.new(t)
                end
            end
        end
    end

    for n in pairs(all - set.new(entry)) do
        idom[n] = tmp[n]
    end

    return idom
end

return fn
