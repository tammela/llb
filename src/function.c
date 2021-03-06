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
#include "function.h"

// ==================================================
//
// instantiates a new function object
//
// ==================================================
int function_new(lua_State* L, LLVMValueRef function) {
    newuserdata(L, function, LLB_FUNCTION);
    return 1;
}

// ==================================================
//
// gets all function's basic blocks
//
// ==================================================
int function_basic_blocks(lua_State* L) {
    LLVMValueRef f = getfunction(L, 1);
    unsigned size = LLVMCountBasicBlocks(f);

    lua_newtable(L);
    if (size == 0) {
        return 1;
    }

    LLVMBasicBlockRef* bbs = calloc(size, sizeof(LLVMBasicBlockRef));
    if (bbs == NULL) {
        return throw(L, "out of memory");
    }

    LLVMGetBasicBlocks(f, bbs);
    for (int i = 0; i < size; i++) {
        bb_new(L, bbs[i]);
        lua_seti(L, -2, i + 1);
    }

    free(bbs);
    return 1;
}

// ==================================================
//
// __tostring metamethod
//
// ==================================================
int function_tostring(lua_State* L) {
    LLVMValueRef f = getfunction(L, 1);
    lua_pushstring(L, LLVMGetValueName(f));
    return 1;
}
