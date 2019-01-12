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

function fn:map_instructions(bbgraph)
    local map, array = {}, {}
    local auxmap = {}

    -- getting all instructions
    local i = 1
    for _, bb in ipairs(bbgraph) do
        array[bb] = {}
        for _, inst in ipairs(bb.ref:instructions()) do
            table.insert(array[bb], inst)
            map[inst] = {
                id = i,
                bb = bb,
                ref = inst,
                usages = {}
            }
            auxmap[inst:pointer()] = map[inst]
            i = i + 1
        end
    end

    -- mapping usages.
    -- where the result of the instruction is used as an argument
    for _, inst in pairs(map) do
        for _, u in ipairs(inst.ref:usages()) do
            local usage = auxmap[u]
            table.insert(inst.usages, usage)
        end
    end

    return map, array
end

-----------------------------------------------------
--
--  prunedssa & auxiliary functions
--
-----------------------------------------------------

--
-- t[bb][tostring(alloca)] => {store instructions}
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
-- f returns the store instruction for the alloca that dominates bb
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
                bb.ref:replace_between(current.reference, next.reference,
                    current.value, current.alloca)
                table.remove(assigns, 1)
            end
            bbstores[bb][kalloca] = bbstores[bb][kalloca][1]
        end
    end
end

local function walk(block, siblings, store, phis)
    local phiblocks
    for alloca, blocks in pairs(phis) do
        if tostring(store.alloca) == tostring(alloca.ref) then
            phiblocks = blocks
            break
        end
    end
    for sibling in pairs(siblings[block]) do
        if not phiblocks:contains(sibling) then
            block.ref:replace_loads(store.alloca, store.value)
            walk(sibling, siblings, store, phis)
        end
    end
end

-- TODO
local function replace_stores_globally(bbgraph, bbstores, ridom, phis)
    for _, block in ipairs(bbgraph) do
        for kalloca, store in pairs(bbstores[block]) do
            walk(block, ridom, store, phis)
            store.reference:delete()
        end
        bbstores[block] = nil
    end
end

--
-- puts the IR in pruned SSA form
-- removes and replaces useless alloca/store/load instructions
--
function fn:prunedssa(builder, bbgraph)
    local bbgraph = bbgraph or self:bbgraph()
    local dom = bbgraph:dom() -- TODO: check if necessary later
    local idom = bbgraph:idom(dom)
    local ridom = bbgraph:ridom(idom)

    local instructions = self:map_instructions(bbgraph)
    local bbstores = bbstores(bbgraph)
    local bbdomstores = bbdomstores(bbstores, idom)

    replace_stores_locally(bbgraph, bbstores)

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

    -- building phis
    for alloca, phis in pairs(phis) do
        local kalloca = tostring(alloca.ref)
        for block in pairs(phis) do
            local incomings = {}
            for predecessor in pairs(block.predecessors) do
                local last = bbstores[predecessor][kalloca]
                local store = last or bbdomstores(predecessor, alloca)
                local incoming = {predecessor.ref}
                if store ~= nil then
                    table.insert(incoming, 1, store.value)
                end
                table.insert(incomings, incoming)
            end
            local phi = block.ref:build_phi(builder, alloca.ref, incomings)
            local value = bbstores[block][kalloca] or phi
            block.ref:replace_between(phi, value, phi, alloca.ref)
        end
    end

    replace_stores_globally(bbgraph, bbstores, ridom, phis)
end

return fn
