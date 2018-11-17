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
set.__index = set

-----------------------------------------------------
--
--  auxiliary
--
-----------------------------------------------------

-- TODO: temporary
-- TODO: should we check for types? is it not automatic?
local function checktypes(...)
    for _, s in ipairs({...}) do
        if getmetatable(s) ~= set then
            error("attempt to perform set operation over non-set value(s)", 2)
        end
    end
end

-----------------------------------------------------
--
--  set
--
-----------------------------------------------------

function set.new(...)
    local t = {}
    setmetatable(t, set)
    t:add(...)
    return t
end

function set:copy()
    return set.new() + self
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

function set:is_empty()
    for _ in pairs(self) do return false end
    return true
end

function set:size()
    local i = 0
    for _ in pairs(self) do i = i + 1 end
    return i
end

function set:__tostring()
    local t = {}
    for e in pairs(self) do
        if type(e) == 'table' then
            table.insert(t, tostring(e.value or e))
        else
            table.insert(t, tostring(e))
        end
    end
    return "{" .. table.concat(t, ", ") .. "}"
end

function set.__add(a, b) -- a `union` b
    checktypes(a, b)
    local t = set.new()
    for e in pairs(a) do t:add(e) end
    for e in pairs(b) do t:add(e) end
    return t
end

function set.__mul(a, b) -- a `intersection` b
    checktypes(a, b)
    local t = set.new()
    for e in pairs(a) do t:add(b[e]) end
    return t
end

function set.__sub(a, b) -- a - b
    checktypes(a, b)
    local t = set.new()
    for e in pairs(a) do
        if not b[e] then
            t:add(e)
        end
    end
    return t
end

function set.__eq(a, b)
    checktypes(a, b)
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
