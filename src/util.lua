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

local util = {}

--
-- returns a copy of a table
--
function table.copy(a)
    local b = {}
    for k, v in pairs(a) do
        b[k] = v
    end
    return b
end

--
-- return a table of all the elements filtered of obj
-- obj can be any object but it must have an pairs iterator
--
function util.filter(obj, f)
    local u = {}
    for k, v in pairs(obj) do
        if f(v) then
            u[k] = v
        end
    end
    return u
end

return util
