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

-- auxiliary
local function bbgraphmap(bbgraph)
    local t = {}
    for _, bb in ipairs(bbgraph) do
        t[tostring(bb.ref)] = bb
    end
    return t
end

local functions = llb.load_ir("aux/book.ll")
assert(functions)
local main = functions.main
assert(main)

do -- bbgraph
    local bbgraph = main:bbgraph()
    assert(bbgraph)
    assert(type(bbgraph) == "table")
    assert(#bbgraph == 8)

    local bb = bbgraphmap(bbgraph)

    -- entry
    assert(bbgraph[1] == bb.entry)
    assert(bb.entry.predecessors:is_empty())
    assert(bb.entry.successors == set.new(bb.b1))

    -- b1
    assert(bb.b1.predecessors == set.new(bb.entry))
    assert(bb.b1.successors == set.new(bb.b2, bb.b3))

    -- b2
    assert(bb.b2.predecessors == set.new(bb.b1))
    assert(bb.b2.successors == set.new(bb.b4, bb.b5))

    -- b3
    assert(bb.b3.predecessors == set.new(bb.b1))
    assert(bb.b3.successors == set.new(bb.b5))

    -- b4
    assert(bb.b4.predecessors == set.new(bb.b2))
    assert(bb.b4.successors == set.new(bb.exit))

    -- b5
    assert(bb.b5.predecessors == set.new(bb.b2, bb.b3))
    assert(bb.b5.successors == set.new(bb.b6))

    -- b6
    assert(bb.b6.predecessors == set.new(bb.b5))
    assert(bb.b6.successors == set.new(bb.exit))

    -- exit
    assert(bb.exit.predecessors == set.new(bb.b4, bb.b6))
    assert(bb.exit.successors:is_empty())
end

do -- domtree
    local bbgraph = main:bbgraph()
    local domtree = main:domtree(bbgraph)
    local bb = bbgraphmap(bbgraph)

    assert(domtree[bb.entry] == set.new(bb.entry))
    assert(domtree[bb.b1] == set.new(bb.entry, bb.b1))
    assert(domtree[bb.b2] == set.new(bb.entry, bb.b1, bb.b2))
    assert(domtree[bb.b3] == set.new(bb.entry, bb.b1, bb.b3))
    assert(domtree[bb.b4] == set.new(bb.entry, bb.b1, bb.b2, bb.b4))
    assert(domtree[bb.b5] == set.new(bb.entry, bb.b1, bb.b5))
    assert(domtree[bb.b6] == set.new(bb.entry, bb.b1, bb.b5, bb.b6))
    assert(domtree[bb.exit] == set.new(bb.entry, bb.b1, bb.exit))
end

do -- idomtree
    local bbgraph = main:bbgraph()
    local idomtree = main:idomtree(bbgraph)
    local bb = bbgraphmap(bbgraph)

    assert(idomtree[bb.entry] == nil)
    assert(idomtree[bb.b1] == bb.entry)
    assert(idomtree[bb.b2] == bb.b1)
    assert(idomtree[bb.b3] == bb.b1)
    assert(idomtree[bb.b4] == bb.b2)
    assert(idomtree[bb.b5] == bb.b1)
    assert(idomtree[bb.b6] == bb.b5)
    assert(idomtree[bb.exit] == bb.b1)
end

-- do -- dflocal, dfup, df
--     local bbgraph = main:bbgraph()
--     local idomtree = main:idomtree(bbgraph)
--     local bb = bbgraphmap(bbgraph)

    
--     local dflx = dflocal(bb.entry, idomtree)
--     print(dflx)
-- end

testing.ok()
