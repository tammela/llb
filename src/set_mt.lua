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

local set_mt = {}

function union(a, b)
    if getmetatable(a) ~= set_mt or getmetatable(b) ~= set_mt then
        error("attempt to 'add' a set with a non-set value", 2)
    end
    local res = {}
    setmetatable(res, set_mt)
    for k in pairs(a) do res[k] = true end
    for k in pairs(b) do res[k] = true end
    return res
end

function intersection(a, b)
    res = {}
    setmetatable(res, set_mt)
    for k in pairs(a) do
        res[k] = b[k]
    end
    return res
end

function remove(a, b)
    res = {}
    setmetatable(res, set_mt)
    for k in pairs(a) do
        if not b[k] then
            res[k] = a[k]
        end
    end
    return res
end

function tostring(s)
    local l = {}
    for e in pairs(s) do
        l[#l + 1] = e
    end
    return "{" .. table.concat( l, ", ") .. "}"
end

set_mt.__add = union
set_mt.__sub = remove
set_mt.__div = intersection
set_mt.__tostring = tostring

return set_mt
