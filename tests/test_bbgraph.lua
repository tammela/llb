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

testing.header("bbgraph.lua")

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

-- bbgraph
local bbgraph = main:bbgraph()
assert(bbgraph)
assert(type(bbgraph) == "table")
assert(#bbgraph == 8)
local bb = bbgraphmap(bbgraph)

do
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

do -- dom
    local dom = bbgraph:dom()
    assert(dom[bb.entry] == set.new(bb.entry))
    assert(dom[bb.b1] == set.new(bb.entry, bb.b1))
    assert(dom[bb.b2] == set.new(bb.entry, bb.b1, bb.b2))
    assert(dom[bb.b3] == set.new(bb.entry, bb.b1, bb.b3))
    assert(dom[bb.b4] == set.new(bb.entry, bb.b1, bb.b2, bb.b4))
    assert(dom[bb.b5] == set.new(bb.entry, bb.b1, bb.b5))
    assert(dom[bb.b6] == set.new(bb.entry, bb.b1, bb.b5, bb.b6))
    assert(dom[bb.exit] == set.new(bb.entry, bb.b1, bb.exit))
end

do -- sdomtree
    local sdom = bbgraph:sdom()
    assert(sdom[bb.entry]:is_empty())
    assert(sdom[bb.b1] == set.new(bb.entry))
    assert(sdom[bb.b2] == set.new(bb.entry, bb.b1))
    assert(sdom[bb.b3] == set.new(bb.entry, bb.b1))
    assert(sdom[bb.b4] == set.new(bb.entry, bb.b1, bb.b2))
    assert(sdom[bb.b5] == set.new(bb.entry, bb.b1))
    assert(sdom[bb.b6] == set.new(bb.entry, bb.b1, bb.b5))
    assert(sdom[bb.exit] == set.new(bb.entry, bb.b1))
end

do -- idom
    local idom = bbgraph:idom()
    assert(idom[bb.entry] == nil)
    assert(idom[bb.b1] == bb.entry)
    assert(idom[bb.b2] == bb.b1)
    assert(idom[bb.b3] == bb.b1)
    assert(idom[bb.b4] == bb.b2)
    assert(idom[bb.b5] == bb.b1)
    assert(idom[bb.b6] == bb.b5)
    assert(idom[bb.exit] == bb.b1)
end

do -- ridom
    local ridom = bbgraph:ridom()
    assert(ridom[bb.entry] == set.new(bb.b1))
    assert(ridom[bb.b1] == set.new(bb.b2, bb.b3, bb.b5, bb.exit))
    assert(ridom[bb.b2] == set.new(bb.b4))
    assert(ridom[bb.b3]:is_empty())
    assert(ridom[bb.b4]:is_empty())
    assert(ridom[bb.b5] == set.new(bb.b6))
    assert(ridom[bb.b6]:is_empty())
    assert(ridom[bb.exit]:is_empty())
end

do -- df
    local df = bbgraph:df()
    assert(df[bb.entry]:is_empty())
    assert(df[bb.b1]:is_empty())
    assert(df[bb.b2] == set.new(bb.b5, bb.exit))
    assert(df[bb.b3] == set.new(bb.b5))
    assert(df[bb.b4] == set.new(bb.exit))
    assert(df[bb.b5] == set.new(bb.exit))
    assert(df[bb.b6] == set.new(bb.exit))
    assert(df[bb.exit]:is_empty())
end

do -- dfplus
    -- a
    local dfp_a = bbgraph:dfplus(set.new(bb.entry))
    assert(dfp_a:is_empty())

    -- x
    local dfp_x = bbgraph:dfplus(set.new(bb.b2, bb.b3))
    assert(dfp_x == set.new(bb.b5, bb.exit))

    -- y
    local dfp_y = bbgraph:dfplus(set.new(bb.b4))
    assert(dfp_y == set.new(bb.exit))

    -- z
    local dfp_z = bbgraph:dfplus(set.new(bb.b1, bb.b5, bb.b6))
    assert(dfp_z == set.new(bb.exit))
end

testing.ok()
