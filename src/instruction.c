/*
 * Lua binding for LLVM C API.
 * Copyright (C) 2018 Matheus Ambrozio, Pedro Tammela, Renan Almeida.
 *
 * This file is part of lua-llvm-binding.
 *
 * lua-llvm-binding is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * lua-llvm-binding is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with lua-llvm-binding. If not, see <http://www.gnu.org/licenses/>.
 */

#include <lauxlib.h>
#include <lua.h>
#include <stdlib.h>

#include <llvm-c/Core.h>

#include "instruction.h"
#include "llbc.h"

int instruction_new(lua_State* L, LLVMValueRef instruction) {
    newuserdata(L, instruction, LLB_INSTRUCTION);
    return 1;
}

int instruction_label(lua_State* L) {
    LLVMValueRef inst = *(LLVMValueRef*)luaL_checkudata(L, 1, LLB_INSTRUCTION);
    lua_pushstring(L, LLVMGetValueName(inst));
    return 1;
}

int instruction_tostring(lua_State* L) {
    LLVMValueRef inst = *(LLVMValueRef*)luaL_checkudata(L, 1, LLB_INSTRUCTION);
    char* str = LLVMPrintValueToString(inst);
    lua_pushstring(L, str);
    LLVMDisposeMessage(str);
    return 1;
}
