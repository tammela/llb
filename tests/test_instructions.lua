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

testing.header("instructions")

local main = llb.load_ir("aux/instruction.ll")["main"]
assert(main)

do -- TODO
    local bbs = main:basic_blocks()
    assert(bbs)

    for i, bb in ipairs(bbs) do
        print(bb)
        local instructions = bb:instructions()
        for i, instruction in ipairs(instructions) do
            print(instruction)
        end
    end

    -- LLVMValueRef LLVMGetOperand(LLVMValueRef, unsigned index);
    -- void LLVMReplaceAllUsesWith(LLVMValueRef old, LLVMValueRef new);
    -- LLVMOpcode LLVMGetInstructionOpcode(LLVMValueRef instruction);
end

testing.ok()









