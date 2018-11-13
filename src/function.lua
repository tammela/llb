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

local function settostring(s)
    local t = {}
    for e in pairs(s) do table.insert(t, tostring(e.value)) end
    return "{" .. table.concat(t, ", ") .. "}"
end

local function graphtostring(graph)
    local nodes = {}
    for _, node in ipairs(graph) do
        local t = {}
        table.insert(t, "label: " .. tostring(node.value))
        table.insert(t, "successors: " .. settostring(node.successors))    
        table.insert(t, "predecessors: " .. settostring(node.predecessors))
        table.insert(nodes, table.concat(t, "\n"))
    end
    return "---\n" .. table.concat(nodes, "\n---\n") .. "\n---"
end

-----------------------------------------------------
--
--  function
--
-----------------------------------------------------

-- computes all predecessors and sucessors of a function
function fn:bbgraph()
    local bbs = self:basic_blocks()
    local nodes = {}
    setmetatable(nodes, {__tostring = graphtostring})
    local auxmap = {}

    for i, bb in ipairs(bbs) do
        nodes[i] = {
            value = bb,
            successors = set.new(),
            predecessors = set.new()
        }
        auxmap[bb:pointer()] = nodes[i]
    end

    for _, node in ipairs(nodes) do
        for _, s in ipairs(node.value:successors()) do
            local successor = auxmap[s]
            node.successors:add(successor)
            successor.predecessors:add(node)
        end
    end

    return nodes
end

-- computes the dominance graph
function fn:domgraph()
    assert(false, "TODO")
end

return fn
