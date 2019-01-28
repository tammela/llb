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
// gets the first instruction of a basic block
//
// ==================================================
int bb_first_instruction(lua_State* L) {
    LLVMBasicBlockRef bb = getbasicblock(L, 1);
    LLVMValueRef first = LLVMGetFirstInstruction(bb);
    return instruction_new(L, first);
}

// ==================================================
//
// gets the last instruction of a basic block
//
// ==================================================
int bb_last_instruction(lua_State* L) {
    LLVMBasicBlockRef bb = getbasicblock(L, 1);
    LLVMValueRef last = LLVMGetLastInstruction(bb);
    return instruction_new(L, last);
}

// ==================================================
//
// build a phi node
//
// ==================================================
int bb_build_phi(lua_State* L) {
    LLVMBasicBlockRef bb = getbasicblock(L, 1);
    LLVMBuilderRef builder = getbuilder(L, 2);
    LLVMValueRef alloca = getinstruction(L, 3);
    LLVMPositionBuilderBefore(builder, LLVMGetFirstInstruction(bb));
    LLVMTypeRef type = LLVMGetAllocatedType(alloca);
    LLVMValueRef phi = LLVMBuildPhi(builder, type, "phi");
    return instruction_new(L, phi);
}

// ==================================================
//
// replaces all uses of load, with alloca operands, to value.
// the replacement procedure is bounded between a1 and a2.
//
// ==================================================
int bb_replace_between(lua_State* L) {
    LLVMValueRef a1 /* current "assign" instruction */ = getinstruction(L, 2);
    LLVMValueRef a2 /* next "assign" instruction    */ = getinstruction(L, 3);
    LLVMValueRef value = getinstruction(L, 4);
    LLVMValueRef alloca = getinstruction(L, 5);
    LLVMValueRef instruction = a1;
    while (instruction && instruction != a2) {
        LLVMValueRef next = LLVMGetNextInstruction(instruction);
        if (LLVMIsALoadInst(instruction) &&
            LLVMGetOperand(instruction, 0) == alloca) {
            LLVMReplaceAllUsesWith(instruction, value);
            LLVMInstructionEraseFromParent(instruction);
        }
        instruction = next;
    }
    return 0;
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
