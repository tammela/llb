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

#include <lua.h>
#include <lauxlib.h>

#include <llvm-c/Core.h>

#include "llb.h"

int bb_new(lua_State *L, LLVMBasicBlockRef basic_block) {
    // bb = {}
    lua_newtable(L);
    // bb.label = name(basic_block)
    lua_pushstring(L, LLVMGetValueName(LLVMBasicBlockAsValue(basic_block))); 
    lua_setfield(L, -2, "label");
    // userdata = newuserdata(basic_block)
    newuserdata(L, LLVMBasicBlockRef, basic_block, LLB_BASIC_BLOCK);
    // bb.userdata = userdata
    lua_setfield(L, -2, "userdata");
    // bb.predecessors = {}
    lua_newtable(L);
    lua_setfield(L, -2, "predecessors");
    // successors = {}
    lua_newtable(L);
    const char* block_label;
    LLVMValueRef terminator = LLVMGetBasicBlockTerminator(basic_block);
    for (int i = 0; i < LLVMGetNumSuccessors(terminator); i++) {
        block_label = LLVMGetBasicBlockName(LLVMGetSuccessor(terminator, i));
        // successors[i] = block_label
        lua_pushstring(L, block_label);
        lua_seti(L, -2, i + 1);
    }
    // bb.successors = successors
    lua_setfield(L, -2, "successors");
    return 1;
}
