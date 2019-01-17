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

--
-- returns t[bb][tostring(alloca)] => {store instructions}
--
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

--
-- returns f(bb, alloca)
-- f returns the store instruction that dominates bb for the alloca
--
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
            local block = idom[bb]
            while block ~= nil do
                if bbstores[block][alloca] ~= nil then
                    t[bb][alloca] = bbstores[block][alloca]
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
-- replaces locally restricted store instructions
-- removes the replaced store instructions from bbstores
--
local function replace_stores_locally(bbgraph, bbstores)
    for _, bb in ipairs(bbgraph) do
        for kalloca, assigns in pairs(bbstores[bb]) do
            while #assigns > 1 do
                local current, next = assigns[1], assigns[2]
                bb.ref:replace_between(
                    current.reference,
                    next.reference,
                    current.value,
                    current.alloca
                )
                current.reference:delete()
                table.remove(assigns, 1)
            end
            bbstores[bb][kalloca] = bbstores[bb][kalloca][1]
        end
    end
end

--
-- computes the predecessors-sucessors graph of a function
--
function fn:bbgraph(bbs)
    local bbs = bbs or self:basic_blocks()
    return bbgraph.new(bbs)
end

--
-- puts the IR in pruned SSA form
-- removes and replaces useless alloca/store/load instructions
--
function fn:prunedssa(builder, bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    local idom = bbgraph:idom()
    local ridom = bbgraph:ridom(idom)

    local instructions = bbgraph:map_instructions()
    local bbstores = bbstores(bbgraph)
    local bbdomstores = bbdomstores(bbstores, idom)

    replace_stores_locally(bbgraph, bbstores)

    -- allocas
    local allocas = instructions:filter(function(e)
        return e.ref:is_alloca()
    end)

    -- phiblocks[alloca] = set<block>
    local phiblocks = {}
    for alloca in pairs(allocas) do
        -- if S is the set of nodes that store with the alloca
        local S = alloca.stores:map(function(store) return store.block end)
        -- DF+(S) is the set of nodes that need phi-functions for the alloca
        phiblocks[alloca] = bbgraph:dfplus(S)
    end

    do -- phiblocks[block] = set<alloca>
        local t = {}
        for _, block in ipairs(bbgraph) do
            t[block] = set.new()
        end
        for alloca, blocks in pairs(phiblocks) do
            for block in pairs(blocks) do
                t[block]:add(alloca)
            end
        end
        phiblocks = t
    end

    -- ridom walking
    local function ridomwalk(block, f)
        f(block)
        for successor in pairs(ridom[block]) do
            ridomwalk(successor, f)
        end
    end

    -- TODO
    local function incoming(phiblock, alloca)
        local t = {}
        for predecessor in pairs(phiblock.predecessors) do
            local last = bbstores[predecessor][tostring(alloca.ref)]
            local store = last or bbdomstores(predecessor, alloca)
            local incoming = {predecessor.ref}
            if store ~= nil then
                table.insert(incoming, 1, store.value)
            end
            table.insert(t, incoming)
        end
        return t
    end

    -- build phis
    local phis = {}
    ridomwalk(bbgraph[1], function(block)
        local allocas = phiblocks[block]
        -- if there are no phis to place in the current block
        if allocas:is_empty() then
            return
        end
        -- placing phis for each alloca
        for alloca in pairs(allocas) do
            local kalloca = tostring(alloca.ref)
            local phi = block.ref:build_phi(builder, alloca.ref)
            phis[tostring(block.ref) .. kalloca] = phi
            local a2
            if bbstores[block][kalloca] ~= nil then
                a2 = bbstores[block][kalloca]
            else
                a2 = phi
                bbstores[block][kalloca] = {
                    reference = phi,
                    value = phi,
                    alloca = alloca
                }
            end
            block.ref:replace_between(phi, a2, phi, alloca.ref)
        end
    end)

    -- add incoming
    ridomwalk(bbgraph[1], function(block)
        local allocas = phiblocks[block]
        -- if no phis were to placed in the current block
        if allocas:is_empty() then
            return
        end
        -- add each incoming
        for alloca in pairs(allocas) do
            local phi = phis[tostring(block.ref) .. tostring(alloca.ref)]
            phi:add_incoming(alloca.ref, incoming(block, alloca))
        end
    end)

    -- replace last loads
    local previous_map = {} -- previous_map[alloca] = assignment
    local function todo(block)
        for alloca in pairs(allocas) do
            local previous = previous_map[alloca]
            local current = bbstores[block][tostring(alloca.ref)]
            local a1, a2, value
            if previous == nil and current ~= nil then
                -- replace [current, END] with current.value
                a1 = current.reference
                a2 = block.ref:last_instruction()
                value = current.value
                block.ref:replace_between(a1, a2, value, alloca.ref)
                -- previous = current
                previous_map[alloca] = current
            elseif previous ~= nil and current == nil then
                -- replace [START, END] with previous.value
                a1 = block.ref:first_instruction()
                a2 = block.ref:last_instruction()
                value = previous.value
                block.ref:replace_between(a1, a2, value, alloca.ref)
            elseif previous ~= nil and current ~= nil then
                -- replace [START, current] with previous.value
                a1 = block.ref:first_instruction()
                a2 = current.reference
                value = previous.value
                block.ref:replace_between(a1, a2, value, alloca.ref)
                -- replace [current, END] with current.value
                a1 = current.reference
                a2 = block.ref:last_instruction()
                value = current.value
                block.ref:replace_between(a1, a2, value, alloca.ref)
                -- previous = current
                previous_map[alloca] = current
            end
        end

        for successor in pairs(ridom[block]) do
            local tmp = table.copy(previous_map)
            todo(successor)
            previous_map = tmp
        end
    end
    todo(bbgraph[1])

    -- delete stores
    -- TODO: this is wrong, what about malloca stores?
    for _, block in ipairs(bbgraph) do
        for _, store in ipairs(block.ref:store_instructions()) do
            store.reference:delete()
        end
    end

    -- delete allocas
    for alloca in pairs(allocas) do
        alloca.ref:delete()
    end
end

return fn
