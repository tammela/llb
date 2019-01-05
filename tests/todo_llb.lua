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

require "setup"

local lib = require "llb"

local err = {
    nonexisting_file = "No such file or directory",
    invalid_ir_file = "aux/invalid.ll:1:1: error: " ..
        "expected top-level entity\ninvalid_ir\n^\n",
    invalid_bc_file = "Invalid bitcode signature"

}
for k, v in pairs(err) do err[k] = "[LLVM] " .. v end

local tests = {{
    func = "load_ir",
    cases = {{
        name = "ok",
        arguments = {"aux/sum.ll"},
        res = function(got)
            return type(got) == "table", "a table", type(got)
        end,
        err = nil
    }, {
        name = "nonexisting file",
        arguments = {"notafile.ll"},
        err = err.nonexisting_file
    }, {
        name = "invalid file",
        arguments = {"aux/invalid.ll"},
        err = err.invalid_ir_file
    }}
}, {
    func = "load_bitcode",
    cases = {{
        name = "ok",
        arguments = {"aux/sum.bc"},
        res = function(got)
            return type(got) == "table", "a table", type(got)
        end,
        err = nil
    }, {
        name = "nonexisting file",
        arguments = {"notafile.bc"},
        err = err.nonexisting_file
    }, {
        name = "invalid file",
        arguments = {"aux/invalid.bc"},
        err = err.invalid_bc_file
    }}
}, {
    func = "write_bitcode",
    cases = {} -- TODO
}}

local function check(t, c, expected, got)
    local f = type(expected) == "function" and
        function(a, b) return a(b) end or
        function(a, b) return a == b, a ,b end
    local ok, e, g = f(expected, got)
    if ok then return end
    local format = "%s - %s: expected <%s>, got <%s>"
    print(string.format(format, t.func, c.name, e, g))
end

for i, test in ipairs(tests) do
    for j, case in ipairs(test.cases) do
        local res, err = lib[test.func](table.unpack(case.arguments))
        check(test, case, case.res, res)
        check(test, case, case.err, err)
    end
end
