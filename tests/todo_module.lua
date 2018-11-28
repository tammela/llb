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

require "setup"

local llb = require "llb"

-- FIXME: not giving errors when trying to load bad .ll files
-- local m = llb.load_ir("aux/ir_1.ll")

local m = llb.load_ir("./aux/sum.ll")

assert(type(m) == "table", "type: " .. type(m))
assert(type(m.userdata) == "userdata", "type: " .. type(m.userdata))
assert(type(m.functions) == "table", "type: " .. type(m.functions))

for function_name, basic_blocks in pairs(m.functions) do
    assert(type(function_name) == "string")
    for basic_block_label, basic_block in pairs(basic_blocks) do
        assert(type(basic_block_label) == "string")
        assert(type(basic_block) == "table")
        assert(type(basic_block.label) == "string")
        assert(type(basic_block.userdata) == "userdata")
        assert(type(basic_block.predecessors) == "table")
        assert(#basic_block.predecessors <= 2)
        assert(type(basic_block.successors) == "table")
        assert(#basic_block.successors <= 2)
    end
end
