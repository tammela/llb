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

local set = {}
set.__index = set -- TODO: why do we need this?

-- auxiliary
local function checkcast(a, b)
    local function f(x)
        return getmetatable(x) == set and x or set.new(table.unpack(x))
    end
    return f(a), f(b)
end

function set.new(...)
    local t = {}
    setmetatable(t, set)
    t:add(...)
    return t
end

function set:add(...)
    for _, e in ipairs({...}) do
        self[e] = e
    end
end

function set:remove(...)
    for _, e in ipairs({...}) do
        self[e] = nil
    end
end

function set:pop()
    for _, v in pairs(self) do
        self:remove(v)
        return v
    end
end

function set:is_empty()
    return next(self) == nil
end

function set:size()
    local i = 0
    for _ in pairs(self) do
        i = i + 1
    end
    return i
end

function set:contains(...)
    for _, e in ipairs({...}) do
        if self[e] == nil then
            return false
        end
    end
    return true
end

function set:__tostring()
    local t = {}
    for e in pairs(self) do
        table.insert(t, tostring(type(e) == "table" and e.ref or e))
    end
    return "{" .. table.concat(t, ", ") .. "}"
end

function set.__add(a, b) -- union
    a, b = checkcast(a, b)
    local t = set.new()
    for e in pairs(a) do t:add(e) end
    for e in pairs(b) do t:add(e) end
    return t
end

function set.__mul(a, b) -- intersection
    a, b = checkcast(a, b)
    local t = set.new()
    for e in pairs(a) do t:add(b[e]) end
    return t
end

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
