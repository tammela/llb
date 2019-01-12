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

local set = {}
set.__index = set -- TODO: why do we need this?

--
-- check if types match, if not creates a 'local' set
--
local function checkcast(a, b)
    local function f(x)
        return getmetatable(x) == set and x or set.new(table.unpack(x))
    end
    return f(a), f(b)
end

--
-- creates a new set object
--
function set.new(...)
    local t = {}
    setmetatable(t, set)
    t:add(...)
    return t
end

--
-- copies a set, returns the new copy
--
function set:copy()
    local t = set.new()
    for e in pairs(self) do
        t:add(e)
    end
    return t
end

--
-- adds n items to the set
--
function set:add(...)
    for _, e in ipairs({...}) do
        self[e] = e
    end
end

--
-- removes n items from the set
--
function set:remove(...)
    for _, e in ipairs({...}) do
        self[e] = nil
    end
end

--
-- pops a item from the set in no particular order
--
function set:pop()
    for _, v in pairs(self) do
        self:remove(v)
        return v
    end
end

--
-- is the set empty?
--
function set:is_empty()
    return next(self) == nil
end

--
-- returns the size of the set
--
function set:size()
    local i = 0
    for _ in pairs(self) do
        i = i + 1
    end
    return i
end

--
-- does it contains these elements?
--
function set:contains(...)
    for _, e in ipairs({...}) do
        if self[e] == nil then
            return false
        end
    end
    return true
end

--
-- __tostring metamethod
-- returns the set in a human understandable way
--
function set:__tostring()
    local t = {}
    for e in pairs(self) do
        table.insert(t, tostring(type(e) == "table" and e.ref or e))
    end
    return "{" .. table.concat(t, ", ") .. "}"
end

--
-- __add metamethod
-- returns a new set that it's the union of a and b
--
function set.__add(a, b)
    a, b = checkcast(a, b)
    local t = set.new()
    for e in pairs(a) do t:add(e) end
    for e in pairs(b) do t:add(e) end
    return t
end

--
-- __mul metamethod
-- returns a new set that it's the intersection of a and b
--
function set.__mul(a, b)
    a, b = checkcast(a, b)
    local t = set.new()
    for e in pairs(a) do t:add(b[e]) end
    return t
end

--
-- __sub metamethod
-- returns a new set that it's the diference of a and b
--
function set.__sub(a, b)
    a, b = checkcast(a, b)
    local t = set.new()
    for e in pairs(a) do
        if not b[e] then
            t:add(e)
        end
    end
    return t
end

--
-- __eq metamethod
-- are the sets exactly the same?
--
function set.__eq(a, b)
    local i = 0
    for e in pairs(a) do
        if not b[e] then
            return false
        end
        i = i + 1
    end
    local j = 0
    for _ in pairs(b) do
        j = j + 1
    end
    return i == j
end

return set
