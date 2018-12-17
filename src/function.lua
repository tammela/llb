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
local bbgraph = require "bbgraph"

local fn = {}

-----------------------------------------------------
--
--  functions
--
-----------------------------------------------------

-- computes the predecessors-sucessors graph of a function
function fn:bbgraph(bbs)
    local bbs = bbs or self:basic_blocks()
    return bbgraph.new(bbs)
end

-- TODO: local?
function fn:map_instructions(bbgraph)
    local instructions = {}
    local auxmap = {}

    -- getting all instructions
    local i = 1
    for _, bb in ipairs(bbgraph) do
        for _, inst in ipairs(bb.ref:instructions()) do
            instructions[inst] = {
                id = i,
                bb = bb,
                ref = inst,
                usages = {}
            }
            auxmap[inst:pointer()] = instructions[inst]
            i = i + 1
        end
    end

    -- mapping usages.
    -- where the result of the instruction is used as an argument
    for _, inst in pairs(instructions) do
        for _, u in ipairs(inst.ref:usages()) do
            local usage = auxmap[u]
            table.insert(inst.usages, usage)
        end
    end

    return instructions
end

-- puts the IR in pruned SSA form
-- removes and replaces useless alloca/store/load instructions
function fn:prunedssa(bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    local instructions = self:map_instructions(bbgraph)

    local phis = {}

    -- for each "alloca" variable "x" 
    for _, instruction in pairs(instructions) do
        if instruction.ref:is_alloca() then
            -- if S is the set of nodes that assign to variable "x"
            local s = set.new()
            for _, usage in pairs(instruction.usages) do
                if usage.ref:is_store() then
                    s:add(usage.bb)
                end
            end
            -- DF+(S) is the set of nodes that need phi-functions for "x"
            phis[instruction] = bbgraph:dfplus(s)
        end
    end

    -- TODO: falta coisa...

    return phis
end

return fn
