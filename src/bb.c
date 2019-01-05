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

#include <stdlib.h>

#include <lauxlib.h>
#include <lua.h>

#include <llvm-c/Core.h>

#include "bb.h"
#include "core.h"
#include "instruction.h"

// ==================================================
//
// instantiates a new basic block object
//
// ==================================================
int bb_new(lua_State* L, LLVMBasicBlockRef bb) {
    newuserdata(L, bb, LLB_BASICBLOCK);
    return 1;
}

// ==================================================
//
// gets a light userdata reference to a basic block
//
// ==================================================
int bb_pointer(lua_State* L) {
    LLVMBasicBlockRef bb = getbasicblock(L, 1);
    lua_pushlightuserdata(L, bb);
    return 1;
}

// ==================================================
//
// gets all successors of a basic block
//
// ==================================================
int bb_successors(lua_State* L) {
    LLVMBasicBlockRef bb = getbasicblock(L, 1);

    LLVMValueRef terminator = LLVMGetBasicBlockTerminator(bb);
    unsigned n_succs = LLVMGetNumSuccessors(terminator);
    lua_newtable(L);
    for (int i = 0; i < n_succs; i++) {
        lua_pushlightuserdata(L, LLVMGetSuccessor(terminator, i));
        lua_seti(L, -2, i + 1);
    }

    return 1;
}

// ==================================================
//
// gets all instructions of a basic block
//
// ==================================================
int bb_instructions(lua_State* L) {
    LLVMBasicBlockRef bb = getbasicblock(L, 1);
    lua_newtable(L);
    int i = 0;
    for (LLVMValueRef inst = LLVMGetFirstInstruction(bb); inst != NULL;
         inst = LLVMGetNextInstruction(inst)) {
        instruction_new(L, inst);
        lua_seti(L, -2, i + 1);
        i++;
    }
    return 1;
}

// ==================================================
//
// __tostring metamethod
//
// ==================================================
int bb_tostring(lua_State* L) {
    LLVMBasicBlockRef bb = getbasicblock(L, 1);
    lua_pushstring(L, LLVMGetBasicBlockName(bb));
    return 1;
}

// ==================================================
//
// TODO
//
// ==================================================

// creates an array with all the store instructions within a basic block
int bb_store_instructions(lua_State* L) {
    LLVMBasicBlockRef bb = getbasicblock(L, 1);
    lua_newtable(L);
    LLVMValueRef instruction = LLVMGetFirstInstruction(bb);
    while (instruction) {
        if (LLVMIsAStoreInst(instruction)) {
            lua_newtable(L);
            instruction_new(L, instruction);
            lua_setfield(L, -2, "reference");
            instruction_new(L, LLVMGetOperand(instruction, 0));
            lua_setfield(L, -2, "value");
            instruction_new(L, LLVMGetOperand(instruction, 1));
            lua_setfield(L, -2, "alloca");
            lua_seti(L, -2, luaL_len(L, -2) + 1);
        }
        instruction = LLVMGetNextInstruction(instruction);
    }
    return 1;
}

int bb_build_phi(lua_State* L) {
    LLVMBasicBlockRef bb = getbasicblock(L, 1);
    LLVMBuilderRef builder = getbuilder(L, 2);
    LLVMValueRef alloca = getinstruction(L, 3);

    LLVMTypeRef alloca_type = LLVMGetAllocatedType(alloca);

    int size = luaL_len(L, 4);
    LLVMValueRef incoming_values[size];
    LLVMBasicBlockRef incoming_blocks[size];

    for (int i = 0; i < size; i++) {
        lua_geti(L, 4, i + 1);
        switch (luaL_len(L, -1)) {
            case 1:
                incoming_values[i] = LLVMGetUndef(alloca_type);
                lua_geti(L, -1, 1);
                incoming_blocks[i] = getbasicblock(L, -1);
                break;
            case 2:
                lua_geti(L, -1, 1);
                incoming_values[i] = getinstruction(L, -1);
                lua_pop(L, 1);
                lua_geti(L, -1, 2);
                incoming_blocks[i] = getbasicblock(L, -1);
                break;
            default:
                UNREACHABLE;
        }
        lua_pop(L, 2);
    }

    LLVMPositionBuilderBefore(builder, LLVMGetFirstInstruction(bb));
    LLVMValueRef phi = LLVMBuildPhi(builder, alloca_type, "phi");
    LLVMAddIncoming(phi, incoming_values, incoming_blocks, size);

    instruction_new(L, phi);
    return 1;
}

int bb_replace_between(lua_State* L) {
    LLVMValueRef a1 /* current "assign" instruction */ = getinstruction(L, 2);
    LLVMValueRef a2 /* next "assign" instruction    */ = getinstruction(L, 3);
    LLVMValueRef value = getinstruction(L, 4);
    LLVMValueRef alloca = getinstruction(L, 5);
    LLVMValueRef instruction = LLVMGetNextInstruction(a1);
    while (instruction && instruction != a2) {
        LLVMValueRef next = LLVMGetNextInstruction(instruction);
        if (LLVMIsALoadInst(instruction) &&
            LLVMGetOperand(instruction, 0) == alloca) {
            // replace all uses of the load with the store's value
            LLVMReplaceAllUsesWith(instruction, value);
            LLVMInstructionEraseFromParent(instruction);
        }
        instruction = next;
    }
    if (LLVMIsAStoreInst(a1)) {
        LLVMInstructionEraseFromParent(a1);
    }
    return 0;
}

int bb_replace_loads(lua_State* L) {
    LLVMBasicBlockRef block = getbasicblock(L, 1);
    LLVMValueRef alloca = getinstruction(L, 2);
    LLVMValueRef value = getinstruction(L, 3);

    LLVMValueRef instruction = LLVMGetFirstInstruction(block);
    while (instruction) {
        LLVMValueRef next = LLVMGetNextInstruction(instruction);
        if (LLVMIsALoadInst(instruction) &&
            LLVMGetOperand(instruction, 0) == alloca) {
            // replace all uses of the load with the store's value

            LLVMDumpValue(instruction);
            printf("\n");

            LLVMReplaceAllUsesWith(instruction, value);
            LLVMInstructionEraseFromParent(instruction);
        }
        instruction = next;
    }
    return 0;
}
