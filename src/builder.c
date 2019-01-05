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

#include <llvm-c/Core.h>

#include "builder.h"
#include "core.h"
#include "function.h"

#include <stdio.h> // TODO: remove

int builder_new(lua_State* L, LLVMBuilderRef builder) {
    newuserdata(L, builder, LLB_BUILDER);
    return 1;
}

int builder_prune_alloca(lua_State* L) {
    // LLVMBuilderRef builder = getbuilder(L, 1);
    // LLVMValueRef alloca =
    //     *(LLVMValueRef*)luaL_checkudata(L, 2, LLB_INSTRUCTION);
    return 0;
}

int builder_position_builder(lua_State* L) {
    LLVMBuilderRef builder =
        *(LLVMBuilderRef*)luaL_checkudata(L, 1, LLB_BUILDER);
    if (lua_gettop(L) == 2) {
        LLVMValueRef inst =
            *(LLVMValueRef*)luaL_checkudata(L, 2, LLB_INSTRUCTION);
        LLVMPositionBuilderBefore(builder, inst);
    } else { // 3
        LLVMBasicBlockRef bb =
            *(LLVMBasicBlockRef*)luaL_checkudata(L, 2, LLB_BASICBLOCK);
        LLVMValueRef inst =
            *(LLVMValueRef*)luaL_checkudata(L, 3, LLB_INSTRUCTION);
        LLVMPositionBuilder(builder, bb, inst);
    }
    return 0;
}

int builder_build_phi(lua_State* L) {
    // TODO complete this function creating the phi and add incoming values
    // Necessary: get LLVMTypeRef of variable that will enter the phi
    return 0;
}
