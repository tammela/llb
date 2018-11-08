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

#include <llvm-c/Core.h>

#include "bb.h"
#include "llbcore.h"

int bb_new(lua_State* L, LLVMBasicBlockRef bb) {
    newuserdata(L, bb, LLB_BASICBLOCK);
    return 1;
}

int bb_pointer(lua_State* L) {
    LLVMBasicBlockRef bb =
        *(LLVMBasicBlockRef*)luaL_checkudata(L, 1, LLB_BASICBLOCK);
    lua_pushlightuserdata(L, bb);
    return 1;
}

int bb_succs(lua_State* L) {
    LLVMBasicBlockRef bb =
        *(LLVMBasicBlockRef*)luaL_checkudata(L, 1, LLB_BASICBLOCK);

    LLVMValueRef terminator = LLVMGetBasicBlockTerminator(bb);
    unsigned n_succs = LLVMGetNumSuccessors(terminator);
    lua_newtable(L);
    for (int i = 0; i < n_succs; i++) {
        lua_pushlightuserdata(L, LLVMGetSuccessor(terminator, i));
        lua_seti(L, -2, i + 1);
    }

    return 1;
}

int bb_tostring(lua_State* L) {
    LLVMBasicBlockRef bb =
        *(LLVMBasicBlockRef*)luaL_checkudata(L, 1, LLB_BASICBLOCK);
    lua_pushstring(L, LLVMGetBasicBlockName(bb));
    return 1;
}
