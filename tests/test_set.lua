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

do
    -- new
    local s = set.new()
    assert(s:is_empty())
    assert(s:size() == 0)
    -- add
    s:add(1)
    assert(not s:is_empty())
    assert(s:size() == 1)
    assert(s[1])
    s:add(2, 3, 4)
    assert(s[1] and s[2] and s[3] and s[4])
    assert(not s:is_empty())
    assert(s:size() == 4)
    -- remove
    s:remove(1)
    assert(not s[1] and s[2] and s[3] and s[4])
    assert(not s:is_empty())
    assert(s:size() == 3)
    s:remove(2, 4)
    assert(not s[1] and not s[2] and s[3] and not s[4])
    assert(not s:is_empty())
    assert(s:size() == 1)
    s:remove(3)
    assert(not s[1] and not s[2] and not s[3] and not s[4])
    assert(s:is_empty())
    assert(s:size() == 0)
end

do -- a + b
    do
        local a = set.new()
        local b = set.new()
        local u = a + b
        assert(u:is_empty())
    end

    do
        local a = set.new()
        local b = set.new()
        a:add("1", "2", "3")
        b:add("4", "5", "6")
        local u = a + b
        assert(u:size() == 6)
    end

    do
        local a = set.new()
        local b = set.new()
        a:add("1", "2", "3")
        b:add("2", "3", "4")
        local u = a + b
        assert(u:size() == 4)
    end

    do
        local a = set.new()
        a:add("1")
        local u = a + a
        assert(u:size() == 1)
    end
end

do -- a * b
    do
        local a = set.new()
        local b = set.new()
        local i = a * b
        assert(i:is_empty())
    end

    do
        local a = set.new()
        local b = set.new()
        a:add("1", "2", "3")
        b:add("4", "5", "6")
        local i = a * b
        assert(i:is_empty())
    end

    do
        local a = set.new()
        local b = set.new()
        a:add("1", "2", "3")
        b:add("2", "3", "4")
        local i = a * b
        assert(i:size() == 2)
    end

    do
        local a = set.new()
        a:add("1")
        local i = a * a
        assert(i:size() == 1)
    end
end

do -- a - b
    do
        local a = set.new()
        local b = set.new()
        local m = a - b
        assert(m:is_empty())
    end

    do
        local a = set.new()
        local b = set.new()
        a:add("1", "2", "3")
        b:add("4", "5", "6")
        local m = a - b
        assert(m:size() == 3)
        assert(m["1"] and m["2"] and m["3"])
    end

    do
        local a = set.new()
        local b = set.new()
        a:add("1", "2", "3")
        b:add("2", "3", "4")
        local m = a - b
        assert(m:size() == 1)
        assert(m["1"])
    end

    do
        local a = set.new()
        a:add("1")
        local m = a - a
        assert(m:is_empty())
    end
end

do -- __tostring
    local s = set.new()
    s:add(2, 3, 4)
    assert(tostring(s) == "{2, 3, 4}")
end

print("-- test set ok")
