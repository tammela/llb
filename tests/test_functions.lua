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

local testing = require "testing"
local llb = require "llb"
local set = require "set"

testing.header("functions.lua")

local function bbgraphmap(bbgraph)
    local t = {}
    for _, bb in ipairs(bbgraph) do
        t[tostring(bb.ref)] = bb
    end
    return t
end

local functions = llb.load_ir("aux/simple.ll")
assert(functions)
local main = functions.main
assert(main)

do -- bbgraph
    local bbgraph = main:bbgraph()
    assert(bbgraph)
    assert(type(bbgraph) == "table")
    assert(#bbgraph == 4)

    local bb = bbgraphmap(bbgraph)

    -- entry
    assert(bbgraph[1] == bb.entry)
    assert(bb.entry.predecessors:is_empty())
    assert(bb.entry.successors == set.new(bb.l1, bb.l2))

    -- l1
    assert(bb.l1.predecessors == set.new(bb.entry))
    assert(bb.l1.successors == set.new(bb.l3))

    -- l2
    assert(bb.l2.predecessors == set.new(bb.entry))
    assert(bb.l2.successors == set.new(bb.l3))

    -- l3
    assert(bb.l3.predecessors == set.new(bb.l1, bb.l2))
    assert(bb.l3.successors:is_empty())
end

do -- domtree
    local bbgraph = main:bbgraph()
    local domtree = main:domtree(bbgraph)
    local bb = bbgraphmap(bbgraph)

    assert(domtree[bb.entry] == set.new(bb.entry))
    assert(domtree[bb.l1] == set.new(bb.entry, bb.l1))
    assert(domtree[bb.l2] == set.new(bb.entry, bb.l2))
    assert(domtree[bb.l3] == set.new(bb.entry, bb.l3))
end

do -- idomtree
    local bbgraph = main:bbgraph()
    local idomtree = main:idomtree(bbgraph)
    local bb = bbgraphmap(bbgraph)

    assert(idomtree[bb.entry] == nil) -- TODO: perhaps {entry = {}} ?
    assert(idomtree[bb.l1] == set.new(bb.entry))
    assert(idomtree[bb.l2] == set.new(bb.entry))
    assert(idomtree[bb.l3] == set.new(bb.entry))
end

testing.ok()









