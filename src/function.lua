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
function fn:prunedssa(builder, bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    local dom = bbgraph:dom() -- TODO: check if necessary later
    local idom = bbgraph:idom(dom)
    local instructions = self:map_instructions(bbgraph)

    -- for each alloca
    local phis = {}
    for _, instruction in pairs(instructions) do
        if instruction.ref:is_alloca() then
            -- if S is the set of nodes that store with the alloca
            local S = set.new()
            for _, usage in pairs(instruction.usages) do
                if usage.ref:is_store() then
                    S:add(usage.bb)
                end
            end
            -- DF+(S) is the set of nodes that need phi-functions for the alloca
            phis[instruction] = bbgraph:dfplus(S)
        end
    end

    local alloca = nil
    local bb = nil

    -- returns the last store instruction for a given alloca
    local function laststore(block, alloca, idom)
        local store = nil
        while block ~= nil and store == nil do
            local stores = block.ref:store_instructions() -- TODO: optimize
            for i = #stores, 1, -1 do
                if alloca.ref:equals(stores[i].alloca) then
                    store = stores[i]
                    break
                end
            end
            block = idom[block]
        end
        return store
    end

    -- building phis
    for alloca, phis in pairs(phis) do
        for block in pairs(phis) do
            local incomings = {}
            for predecessor in pairs(block.predecessors) do
                local store = laststore(predecessor, alloca, idom)
                local incoming = {predecessor.ref}
                if store ~= nil then
                    table.insert(incoming, 1, store.value)
                end
                table.insert(incomings, incoming)
            end
            block.ref:build_phi(builder, alloca.ref, incomings)
            -- print("--------------------")
            -- print(phi.ref)
            -- print(alloca.ref)
            -- for predecessor, store in pairs(phifrom) do
            --     print("predecessor(" .. tostring(predecessor.ref) .. ")")
            --     print(store.reference)
            -- end
        end
    end

    -- -- TODO: bagunça - refatorar
    -- -- pruning variables that don't need a phi
    -- -- TODO: this is wrong - imagine a single entry block program
    -- for alloca, phiblocks in pairs(phis) do
    --     if phiblocks:is_empty() then
    --         local store
    --         for _, usage in ipairs(alloca.usages) do
    --             if usage.ref:is_store() then
    --                 store = usage
    --             end
    --         end
    --         local storedvalue = store.ref:operands()[1]
    --         for _, usage in ipairs(alloca.usages) do
    --             if usage.ref:is_load() then
    --                 usage.ref:replace_with(storedvalue)
    --                 usage.ref:delete()
    --             end
    --         end
    --         alloca.ref:delete()
    --         store.ref:delete()
    --         phis[alloca] = nil -- TODO: is this safe?
    --     end
    -- end

    -- -- placing phis
    -- for alloca, blocks in pairs(phis) do
    --     for block in pairs(blocks) do
    --         local last_usage = alloca.usages[#alloca.usages].ref
    --         print(alloca.ref, block.ref, last_usage)
    --     end
    -- end

    -- -- TODO

    -- -- TODO: bagunça - refatorar
    -- local function remove(alloca)
    --     local visited = {}
    --     local function dfs(bb, visited)
    --         -- print("basic block: ", bb.ref)
    --         for successor in pairs(bb.successors) do
    --             if visited[successor] == nil then
    --                 visited[successor] = successor
    --                 -- 
    --                 for _, instruction in ipairs(bb.ref:instructions()) do
    --                     if instruction:is_store() then
    --                         local operands = instruction:operands()
    --                         local store_value = operands[1]
    --                         local store_alloca = operands[2]
    --                         if alloca.ref:equals(store_alloca) then
    --                             alloca.replace_with = store_value
    --                         end
    --                     elseif instruction:is_load() then
    --                         local operands = instruction:operands()
    --                         local load_alloca = operands[1]
    --                         if alloca.ref:equals(load_alloca) then
    --                             instruction:replace_with(alloca.replace_with)
    --                             instruction:delete()
    --                         end
    --                     end
    --                 end
    --                 -- 
    --                 dfs(successor, visited)
    --             end
    --         end
    --     end
    --     dfs(bbgraph[1], visited)
    -- end
    -- for alloca in pairs(phis) do
    --     remove(alloca)
    -- end

    return phis
end

return fn
