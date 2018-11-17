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
            value = bb, -- why call this value? this is the __llb_basicblock reference
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



local function dumptable(t)
    for k, v in pairs(t) do print(k.value, v) end
end





function temp(all, entry)
    local D -- set<node>
    local T -- set<node>
    local change = true
    local dom = {} -- {node: set<node>}

    dom[entry] = set.new(entry)
    for e in pairs(all - set.new(entry)) do
        dom[e] = all
    end

    repeat
        change = false
        for n in pairs(all - set.new(entry)) do
            -- print("n = " .. tostring(n.value))
            T = all:copy()
            -- print("\tT (all) = " .. tostring(T))
            for p in pairs(n.predecessors) do
                -- print("\tp antes = " .. tostring(p.value))
                T = T * dom[p]
                -- print("\t\tT (T * " .. tostring(dom[p]) .. ") = " .. tostring(T))
                -- print("\t\tdom[" .. tostring(p.value) .. "] = " .. tostring(dom[p]))
                -- print("\tp depois = " .. tostring(p.value))
            end
            D = set.new(n) + T
            -- print("\tD = " .. tostring(D) .. " | " .. "dom[" .. tostring(n.value) .. "] = " .. tostring(dom[n]))
            if D ~= dom[n] then
                change = true
                dom[n] = D
            end
        end
    until not change

    print("\n")

    return dom
end

-- computes the dominance graph of a function
function fn:domgraph()
    local bbgraph = self:bbgraph()
    local bbset = set.new()
    bbset:add(table.unpack(bbgraph))
    local dom = temp(bbset, bbgraph[1])

    dumptable(dom)
end

return fn
