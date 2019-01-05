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

local testing = require "testing"
local llb = require "llb"
local set = require "set"

testing.header("functions.lua")

-- auxiliary
local function bbgraphmap(bbgraph)
    local t = {}
    for _, bb in ipairs(bbgraph) do
        t[tostring(bb.ref)] = bb
    end
    return t
end

local module = llb.load_ir("aux/book.ll")
assert(module)
local main = module.main
assert(main)

do -- bbgraph
    local bbgraph = main:bbgraph()
    assert(bbgraph)
    assert(type(bbgraph) == "table")
    assert(#bbgraph == 8)
    -- complete test in test_bbgraph.lua
end

-- do -- map_instructions
--     local instructions = main:map_instructions()
--     for k, v in pairs(instructions) do
--         print(k, v)
--     end
--     print(instructions)
-- end

do -- prunedssa
    local builder = getmetatable(module).get_builder(module) -- FIXME: ?
    assert(builder)
    local bbgraph = main:bbgraph()
    local phis = main:prunedssa(builder, bbgraph)
    llb.write_bitcode(module, "testando.bc")
end

-- -- TODO: move
-- do -- bb:store_instructions
--     local bbgraph = main:bbgraph()
--     for _, bb in ipairs(bbgraph) do
--         print(bb.ref)
--         for i, store in ipairs(bb.ref:store_instructions()) do
--             print("---", i)
--             print(store.reference)
--             print(store.value)
--             print(store.alloca)
--         end
--     end
-- end

testing.ok()
