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
local set = require "set"

testing.header("set.lua")

do -- new
    do -- empty
        local s = set.new()
        assert(s:is_empty())
    end

    do -- one
        local s = set.new(1)
        assert(s:size() == 1)
        assert(s:contains(1))
    end

    do -- many
        local s = set.new(1, 2, 3)
        assert(s:size() == 3)
        assert(s:contains(1, 2, 3))
    end
end

do -- add & remove
    local s = set.new()

    -- add (one)
    s:add("a")
    assert(s:size() == 1)
    assert(s:contains("a"))

    -- add (many)
    s:add("b", "c", "d")
    assert(s:size() == 4)
    assert(s:contains("a", "b", "c", "d"))

    -- add (repeated)
    s:add("b")
    assert(s:size() == 4)
    assert(s:contains("a", "b", "c", "d"))
    
    -- remove (one)
    s:remove("b")
    assert(s:size() == 3)
    assert(s["a"] and not s["b"] and s["c"] and s["d"])
    assert(s:contains("a", "c", "d") and not s["b"])
    
    -- remove (many)
    s:remove("a", "d")
    assert(s:size() == 1)
    assert(s:contains("c") and not s["a"] and not s["b"] and not s["d"])
    
    -- remove (non existing)
    s:remove("e")
    assert(s:size() == 1)
    assert(s:contains("c") and not s["a"] and not s["b"] and not s["d"])
end

-- is_empty & size & contains (tested above)

do -- __tostring
    do -- simple
        local s = set.new(1, 2, 3)
        assert(tostring(s) == "{1, 2, 3}")
    end

    do -- reference
       local s = set.new({ref = "A"}, {ref = "B"})
        assert(tostring(s) == "{A, B}") 
    end
end

do -- union
    do -- empty sets
        local a = set.new()
        local b = set.new()
        local s

        s = a + b
        assert(s:is_empty())

        s = a + {}
        assert(s:is_empty())

        s = {} + b
        assert(s:is_empty())
    end

    do -- non-empty sets
        local a = set.new(1, 2, 3)
        local b = set.new(4, 5, 6)
        local s

        s = a + b
        assert(s == set.new(1, 2, 3, 4, 5, 6))

        s = a + {4}
        assert(s == set.new(1, 2, 3, 4))        

        s = {1} + b
        assert(s == set.new(1, 4, 5, 6))
    end

    do -- sets with an intersection
        local a = set.new(1, 2, 3)
        local b = set.new(2, 3, 4)
        local s = a + b
        assert(s == set.new(1, 2, 3, 4))
    end

    do -- same set
        local a = set.new(1)
        local s = a + a
        assert(s == a)
    end
end

do -- intersection
    do -- empty sets
        local a = set.new()
        local b = set.new()
        local s

        s = a * b
        assert(s:is_empty())

        s = a * {}
        assert(s:is_empty())

        s = {} * b
        assert(s:is_empty())
    end

    do -- non-empty sets
        local a = set.new(1, 2, 3)
        local b = set.new(4, 5, 6)
        local s

        s = a * b
        assert(s == set.new())

        s = a * {2}
        assert(s == set.new(2))

        s = {6, 4} * b
        assert(s == set.new(4, 6))
    end

    do -- sets with an intersection
        local a = set.new(1, 2, 3)
        local b = set.new(2, 3, 4)
        local s = a * b
        assert(s == set.new(2, 3))
    end

    do -- same set
        local a = set.new(1)
        local s = a * {1}
        assert(s == a)
    end

    do -- a * {}
        local a = set.new("a", "b", "c")
        local s = a * {}
        assert(s == set.new())
    end
end

do -- subtraction
    do -- empty sets
        local a = set.new()
        local b = set.new()
        local s

        s = a - b
        assert(s:is_empty())

        s = a - {}
        assert(s:is_empty())

        s = {} - b
        assert(s:is_empty())
    end

    do -- non-empty sets
        local a = set.new(1, 2, 3)
        local b = set.new(4, 5, 6)
        local s

        s = a - b
        assert(s == a)

        s = a - {2}
        assert(s == set.new(1, 3))

        s = {4, 6} - b
        assert(s == set.new())
    end

    do -- sets with an intersection
        local a = set.new(1, 2, 3)
        local b = set.new(2, 3, 4)
        local s = a - b
        assert(s == set.new(1))
    end

    do -- same set
        local a = set.new(5)
        local m = a - {5}
        assert(m:is_empty())
    end
end

do -- equality
    do
        local a = set.new(1)
        local b = set.new(2)
        assert(a ~= b)
        b:add(1)
        assert(a ~= b)
        b:remove(2)
        assert(a == b)
    end

    do
        local a = set.new()
        local b = set.new(1, 2, 3, 4, 6)
        a:add(1, 2, 3, 4, 6)
        assert(a == b)
        a:remove(3)
        assert(a ~= b)
        a:add(3)
        assert(a == b)
    end
end

testing.ok()
