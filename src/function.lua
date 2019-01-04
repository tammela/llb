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

-----------------------------------------------------
--
--  prunedssa & auxiliary functions
--
-----------------------------------------------------

-- t[bb][tostring(alloca)] => {store instructions}
local function bbstores(bbgraph)
    local t = {}
    for _, bb in ipairs(bbgraph) do
        t[bb] = {}
        for _, store in ipairs(bb.ref:store_instructions()) do
            local kalloca = tostring(store.alloca)
            if t[bb][kalloca] == nil then
                t[bb][kalloca] = {}
            end
            table.insert(t[bb][kalloca], store)
        end
    end
    return t
end

local function laststore(stores)
    if stores == nil then
        return nil
    end
    return stores[#stores]
end

-- returns f(bb, alloca) that returns dominant last store instruction
local function bbdomstores(bbstores, idom)
    local t = {}
    return function(bb, alloca)
        alloca = tostring(alloca.ref)
        if t[bb] == nil then
            t[bb] = {}
        end
        if t[bb][alloca] ~= nil then
            goto done
        end
        do
            local block = bb
            while block ~= nil do
                local last = laststore(bbstores[block][alloca])
                if last ~= nil then
                    t[bb][alloca] = last
                    goto done
                end
                block = idom[block]
            end
        end
        ::done::
        return t[bb][alloca]
    end
end

-- replaces locally restricted store instructions
local function replacelocal(bbgraph, bbstores)
    for _, bb in ipairs(bbgraph) do
        for kalloca, stores in pairs(bbstores[bb]) do
            for i = 1, #stores - 1 do
                local current, next = stores[i], stores[i + 1]
                bb.ref:replace_between(current.reference, next.reference,
                    current.value, current.alloca)
            end
        end
    end
end

-- puts the IR in pruned SSA form
-- removes and replaces useless alloca/store/load instructions
function fn:prunedssa(builder, bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    local dom = bbgraph:dom() -- TODO: check if necessary later
    local idom = bbgraph:idom(dom)

    local instructions = self:map_instructions(bbgraph)
    local bbstores = bbstores(bbgraph)
    local bbdomstores = bbdomstores(bbstores, idom)

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

    -- WIP
    replacelocal(bbgraph, bbstores)

    -- building phis
    for alloca, phis in pairs(phis) do
        for block in pairs(phis) do
            local incomings = {}
            for predecessor in pairs(block.predecessors) do
                local store = bbdomstores(predecessor, alloca)
                local incoming = {predecessor.ref}
                if store ~= nil then
                    table.insert(incoming, 1, store.value)
                end
                table.insert(incomings, incoming)
            end
            -- print("--------------------")
            -- print(block.ref)
            -- print(alloca.ref)
            -- for _, tuple in pairs(incomings) do
            --     if #tuple == 1 then
            --         local format = "predecessor(%s) => undef\n"
            --         io.write(string.format(format, tuple[1]))
            --     elseif #tuple == 2 then
            --         local format = "predecessor(%s) => %s\n"
            --         io.write(string.format(format, tuple[2], tuple[1]))
            --     end
            -- end
            block.ref:build_phi(builder, alloca.ref, incomings)
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
