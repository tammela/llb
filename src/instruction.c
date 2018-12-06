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

#include "core.h"
#include "instruction.h"

#define getinstruction(L) \
    (*(LLVMValueRef*)luaL_checkudata(L, 1, LLB_INSTRUCTION))

int instruction_new(lua_State* L, LLVMValueRef instruction) {
    newuserdata(L, instruction, LLB_INSTRUCTION);
    return 1;
}

int instruction_pointer(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L);
    lua_pushlightuserdata(L, instruction);
    return 1;
}

int instruction_label(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L);
    lua_pushstring(L, LLVMGetValueName(instruction));
    return 1;
}

int instruction_operands(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L);
    int num_operands = LLVMGetNumOperands(instruction);

    lua_newtable(L);
    for (int i = 0; i < num_operands; i++) {
        lua_pushlightuserdata(L, LLVMGetOperand(instruction, i));
        lua_seti(L, -2, i + 1);
    }

    return 1;
}

int instruction_usages(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L);

    lua_newtable(L);

    int i = 0;
    for (LLVMUseRef use = LLVMGetFirstUse(instruction); use != NULL;
         use = LLVMGetNextUse(use)) {
        LLVMValueRef used_in = LLVMGetUser(use);
        char* str = LLVMPrintValueToString(instruction);
        char* str2 = LLVMPrintValueToString(used_in);
        printf("%s: %s\n", str, str2);
        lua_pushlightuserdata(L, used_in);
        lua_seti(L, -2, i + 1);
        i++;
    }

    return 1;
}

int instruction_tostring(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L);
    char* str = LLVMPrintValueToString(instruction);
    lua_pushstring(L, str);
    LLVMDisposeMessage(str);
    return 1;
}
