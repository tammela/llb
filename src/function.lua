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
local bbgraph = require "bbgraph"

local fn = {}

-- auxiliary
function tablecopy(a)
    local b = {}
    for k, v in pairs(a) do
        b[k] = v
    end
    return b
end

-----------------------------------------------------
--
--  functions
--
-----------------------------------------------------

--
-- computes the predecessors-sucessors graph of a function
--
function fn:bbgraph(bbs)
    local bbs = bbs or self:basic_blocks()
    return bbgraph.new(bbs)
end

-----------------------------------------------------
--
--  prunedssa & auxiliary functions
--
-----------------------------------------------------

-- 
-- returns instructions, block_instructions 
-- instructions = set<instruction>
-- block_instructions[block] => {instruction}
-- 
local function mapinstructions(bbgraph)
    local instructions = set.new()
    local block_instructions, auxmap = {}, {}
    for _, block in ipairs(bbgraph) do
        block_instructions[block] = {}
        for _, reference in ipairs(block.ref:instructions()) do
            local instruction = {
                block = block,
                ref = reference,
                stores = set.new()
            }
            instructions:add(instruction)
            table.insert(block_instructions[block], instruction)
            auxmap[reference:pointer()] = instruction
        end
    end
    for instruction in pairs(instructions) do
        if instruction.ref:is_store() then
            instruction.is_store = true
            local operands = instruction.ref:operands()
            local found = auxmap[operands[1]:pointer()]
            instruction.value = found ~= nil and found or {ref = operands[1]}
            instruction.alloca = assert(auxmap[operands[2]:pointer()])
        elseif instruction.ref:is_alloca() then
            instruction.is_alloca = true
        end
        for _, usage in ipairs(instruction.ref:usages()) do
            local usage_instruction = auxmap[usage]
            if usage_instruction.ref:is_store() then
                instruction.stores:add(usage_instruction)
            end
        end
    end
    return instructions, block_instructions
end

--
-- returns t[block][alloca] => {store instructions}
--
local function bbassignments(block_instructions)
    local t = {}
    for block, instructions in pairs(block_instructions) do
        t[block] = {}
        for _, instruction in ipairs(instructions) do
            if instruction.is_store then
                if t[block][instruction.alloca] == nil then
                    t[block][instruction.alloca] = {}
                end
                table.insert(t[block][instruction.alloca], instruction)
            end
        end
    end
    return t
end

--
-- returns f(block, alloca)
-- f returns the assignment instruction that dominates "block" for the alloca
--
local function bbdomassignments(bbassignments, idom)
    local t = {}
    return function(bb, alloca)
        if t[bb] == nil then
            t[bb] = {}
        end
        if t[bb][alloca] ~= nil then
            goto done
        end
        do
            local block = idom[bb]
            while block ~= nil do
                if bbassignments[block][alloca] ~= nil then
                    t[bb][alloca] = bbassignments[block][alloca]
                    goto done
                end
                block = idom[block]
            end
        end
        ::done::
        return t[bb][alloca]
    end
end

-- 
-- calculatesthe set of alloca instructions that need a phi for each block
-- returns t[block] => set<alloca>
-- 
local function bbphis(bbgraph, allocas)
    -- t[alloca] = set<block>
    local t = {}
    for alloca in pairs(allocas) do
        -- if S is the set of nodes that store in the alloca
        local S = alloca.stores:map(function(store) return store.block end)
        -- DF+(S) is the set of nodes that need phi-functions for the alloca
        t[alloca] = bbgraph:dfplus(S)
    end

    -- mirroring
    local mirror = {}
    for _, block in ipairs(bbgraph) do
        mirror[block] = set.new()
    end
    for alloca, blocks in pairs(t) do
        for block in pairs(blocks) do
            mirror[block]:add(alloca)
        end
    end

    return mirror
end

-- 
-- DFS from entry
-- 
local function dfs(t, entry)
    local function tdfs(block, before, after, pre, post)
        if before ~= nil then
            before(block)
        end
        for successor in pairs(t[block]) do
            local pre = pre == nil or pre()
            tdfs(successor, before, after)
            if post ~= nil then post(pre) end
        end
        if after ~= nil then
            after(block)
        end
    end
    return function(before, after, pre, post)
        tdfs(entry, before, after, pre, post)
    end
end

--
-- transforms the IR to its pruned SSA form
--
function fn:prunedssa(builder, bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    local idom = bbgraph:idom()
    local ridom = bbgraph:ridom(idom)

    -- instructions = set<instruction>
    -- block_instructions[block] => {instruction}
    local instructions, block_instructions = mapinstructions(bbgraph)
    -- bbassignments[block][alloca] => {store instruction}
    local bbassignments = bbassignments(block_instructions)
    -- bbdomassignments(block, alloca) => assignment
    local bbdomassignments = bbdomassignments(bbassignments, idom)

    -- replaces locally restricted store instructions
    -- removes locally restricted load instructions
    -- removes the replaced store instructions from bbassignments
    -- changes bbassignments to t[block][alloca] => (store instruction) or nil
    for _, block in ipairs(bbgraph) do
        for alloca, assignments in pairs(bbassignments[block]) do
            while #assignments > 1 do
                local current, next = assignments[1], assignments[2]
                block.ref:replace_between(
                    current.ref,
                    next.ref,
                    current.value.ref,
                    current.alloca.ref
                )
                current.ref:delete()
                table.remove(assignments, 1)
            end
            bbassignments[block][alloca] = bbassignments[block][alloca][1]
        end
    end

    -- set of alloca instructions
    local allocas = instructions:filter(function(e) return e.is_alloca end)
    -- bbphis[block] => set<alloca>
    local bbphis = bbphis(bbgraph, allocas)
    -- ridomdfs(f, pre, post) from entry
    local ridomdfs = dfs(ridom, bbgraph[1])

    -- phis[block][alloca] => (phi instruction) or nil
    local phis = {}

    -- places the required phi instructions for each block
    -- removes the associated locally restricted load instructions
    ridomdfs(function(block)
        for alloca in pairs(bbphis[block]) do
            local phi = block.ref:build_phi(builder, alloca.ref)
            if phis[block] == nil then phis[block] = {} end
            phis[block][alloca] = phi
            local boundary
            if bbassignments[block][alloca] ~= nil then
                -- there is a store instruction in the block
                boundary = bbassignments[block][alloca]
            else
                -- there isn't a store instruction in the block
                -- bbassignments must be updated
                boundary = phi
                local phi_instruction = {ref = phi, alloca = alloca}
                phi_instruction.value = phi_instruction
                bbassignments[block][alloca] = phi_instruction
            end
            block.ref:replace_between(phi, boundary, phi, alloca.ref)
        end
    end)

    -- adds the incoming (value, block) tuples to the phi instructions 
    ridomdfs(function(block)
        for alloca in pairs(bbphis[block]) do
            local t = {}
            for predecessor in pairs(block.predecessors) do
                local last = bbassignments[predecessor][alloca]
                local assignment = last or bbdomassignments(predecessor, alloca)
                local incoming = {predecessor.ref}
                if assignment ~= nil then
                    table.insert(incoming, 1, assignment.value.ref)
                end
                table.insert(t, incoming)
            end
            phis[block][alloca]:add_incoming(alloca.ref, t)
        end
    end)

    -- auxiliary map
    -- previous_map[alloca] => assignment
    local previous_map = {}

    -- replaces the remaining assignments and loads between blocks
    ridomdfs(function(block) -- before
        for alloca in pairs(allocas) do
            local previous = previous_map[alloca]
            local current = bbassignments[block][alloca]
            local a1, a2, value
            if previous == nil and current ~= nil then
                -- replace [current, END] with current.value
                a1 = current.ref
                a2 = block.ref:last_instruction()
                value = current.value.ref
                block.ref:replace_between(a1, a2, value, alloca.ref)
                -- previous = current
                previous_map[alloca] = current
            elseif previous ~= nil and current == nil then
                -- replace [START, END] with previous.value
                a1 = block.ref:first_instruction()
                a2 = block.ref:last_instruction()
                value = previous.value.ref
                block.ref:replace_between(a1, a2, value, alloca.ref)
            elseif previous ~= nil and current ~= nil then
                -- replace [START, current] with previous.value
                a1 = block.ref:first_instruction()
                a2 = current.ref
                value = previous.value.ref
                block.ref:replace_between(a1, a2, value, alloca.ref)
                -- replace [current, END] with current.value
                a1 = current.ref
                a2 = block.ref:last_instruction()
                value = current.value.ref
                block.ref:replace_between(a1, a2, value, alloca.ref)
                -- previous = current
                previous_map[alloca] = current
            end
        end
    end, function(block) -- after
        for _, assignment in pairs(bbassignments[block]) do
            if assignment.is_store then
                assignment.ref:delete()
            end
        end
    end, function() -- pre
        return tablecopy(previous_map)
    end, function(pre) --post
        previous_map = pre
    end)

    -- deletes all alloca instructions
    allocas:map(function(e) e.ref:delete() end)
end

return fn
