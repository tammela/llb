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
    local dom = main:domtree(bbgraph)
    local bb = bbgraphmap(bbgraph)

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
    local bbgraph = main:bbgraph()
    local sdom = main:sdomtree(bbgraph)
    local bb = bbgraphmap(bbgraph)

    assert(sdom[bb.entry]:is_empty())
    assert(sdom[bb.b1] == set.new(bb.entry))
    assert(sdom[bb.b2] == set.new(bb.entry, bb.b1))
    assert(sdom[bb.b3] == set.new(bb.entry, bb.b1))
    assert(sdom[bb.b4] == set.new(bb.entry, bb.b1, bb.b2))
    assert(sdom[bb.b5] == set.new(bb.entry, bb.b1))
    assert(sdom[bb.b6] == set.new(bb.entry, bb.b1, bb.b5))
    assert(sdom[bb.exit] == set.new(bb.entry, bb.b1))
end

do -- idomtree
    local bbgraph = main:bbgraph()
    local idom = main:idomtree(bbgraph)
    local bb = bbgraphmap(bbgraph)

    assert(idom[bb.entry] == nil)
    assert(idom[bb.b1] == bb.entry)
    assert(idom[bb.b2] == bb.b1)
    assert(idom[bb.b3] == bb.b1)
    assert(idom[bb.b4] == bb.b2)
    assert(idom[bb.b5] == bb.b1)
    assert(idom[bb.b6] == bb.b5)
    assert(idom[bb.exit] == bb.b1)
end

do -- ridomtree
    local bbgraph = main:bbgraph()
    local ridom = main:ridomtree(bbgraph)
    local bb = bbgraphmap(bbgraph)

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
    local bbgraph = main:bbgraph()
    local df = main:df(bbgraph)
    local bb = bbgraphmap(bbgraph)

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
    local bbgraph = main:bbgraph()
    local bb = bbgraphmap(bbgraph)

    -- a
    local dfp_a = main:dfplus(bbgraph, set.new(bb.entry))
    assert(dfp_a:is_empty())

    -- x
    local dfp_x = main:dfplus(bbgraph, set.new(bb.b2, bb.b3))
    assert(dfp_x == set.new(bb.b5, bb.exit))

    -- y
    local dfp_y = main:dfplus(bbgraph, set.new(bb.b4))
    assert(dfp_y == set.new(bb.exit))

    -- z
    local dfp_z = main:dfplus(bbgraph, set.new(bb.b1, bb.b5, bb.b6))
    assert(dfp_z == set.new(bb.exit))
end

testing.ok()
