/*
 * Lua binding for LLVM C API.
 * Copyright (C) 2018 Matheus Ambrozio, Pedro Tammela, Renan Almeida.
 *
 * This file is part of llb.
 *
 * llb is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * llb is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with llb. If not, see <http://www.gnu.org/licenses/>.
 */

#include <lauxlib.h>
#include <lua.h>
#include <stdlib.h>

#include <llvm-c/Core.h>

#include "bb.h"
#include "core.h"
#include "instruction.h"

// ==================================================
//
// instantiates a new instruction object
//
// ==================================================
int instruction_new(lua_State* L, LLVMValueRef instruction) {
    newuserdata(L, instruction, LLB_INSTRUCTION);
    return 1;
}

// ==================================================
//
// returns the bb who owns this instruction
//
// ==================================================
int instruction_parent(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L, 1);
    return bb_new(L, LLVMGetInstructionParent(instruction));
}

// ==================================================
//
// returns a reference to instruction
//
// ==================================================
int instruction_pointer(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L, 1);
    lua_pushlightuserdata(L, instruction);
    return 1;
}

// ==================================================
//
// returns the instruction label
//
// ==================================================
int instruction_label(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L, 1);
    lua_pushstring(L, LLVMGetValueName(instruction));
    return 1;
}

// ==================================================
//
// creates a table with all the operands of a instruction
//
// ==================================================
int instruction_operands(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L, 1);
    int num_operands = LLVMGetNumOperands(instruction);
    lua_newtable(L);
    for (int i = 0; i < num_operands; i++) {
        newuserdata(L, LLVMGetOperand(instruction, i), LLB_INSTRUCTION);
        lua_seti(L, -2, i + 1);
    }
    return 1;
}

// ==================================================
//
// creates a table with all the usages of a instruction
//
// ==================================================
int instruction_usages(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L, 1);
    lua_newtable(L);
    int i = 0;
    for (LLVMUseRef use = LLVMGetFirstUse(instruction); use != NULL;
         use = LLVMGetNextUse(use)) {
        LLVMValueRef used_in = LLVMGetUser(use);
        lua_pushlightuserdata(L, used_in);
        lua_seti(L, -2, i + 1);
        i++;
    }
    return 1;
}

int instruction_is_alloca(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L, 1);
    lua_pushboolean(L, LLVMIsAAllocaInst(instruction) ? 1 : 0);
    return 1;
}

int instruction_is_phi(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L, 1);
    lua_pushboolean(L, LLVMIsAPHINode(instruction) ? 1 : 0);
    return 1;
}

int instruction_is_store(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L, 1);
    lua_pushboolean(L, LLVMIsAStoreInst(instruction) ? 1 : 0);
    return 1;
}

int instruction_is_load(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L, 1);
    lua_pushboolean(L, LLVMIsALoadInst(instruction) ? 1 : 0);
    return 1;
}

// ==================================================
//
// replace a instruction
//
// ==================================================
int instruction_replace_with(lua_State* L) {
    LLVMValueRef old = getinstruction(L, 1);
    LLVMValueRef new = getinstruction(L, 2);
    LLVMReplaceAllUsesWith(old, new);
    return 1;
}

// ==================================================
//
// delete an instruction from the module
//
// ==================================================
int instruction_delete(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L, 1);
    LLVMInstructionEraseFromParent(instruction);
    return 1;
}

// ==================================================
//
// check if the reference of two instructions are the same
//
// ==================================================
int instruction_equals(lua_State* L) {
    LLVMValueRef i1 = getinstruction(L, 1);
    LLVMValueRef i2 = getinstruction(L, 2);
    lua_pushboolean(L, i1 == i2 ? 1 : 0);
    return 1;
}

// ==================================================
//
// __tostring metamethod
//
// ==================================================
int instruction_tostring(lua_State* L) {
    LLVMValueRef instruction = getinstruction(L, 1);
    char* str = LLVMPrintValueToString(instruction);
    lua_pushstring(L, str);
    LLVMDisposeMessage(str);
    return 1;
}
