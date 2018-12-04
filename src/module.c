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

#include "function.h"
#include "llbc.h"

#define getmodule(L) \
    (*(LLVMModuleRef*)luaL_checkudata(L, 1, LLB_MODULE))

int module_new(lua_State* L, LLVMModuleRef module) {
    newuserdata(L, module, LLB_MODULE);
    return 1;
}

int module_gc(lua_State* L) {
    LLVMModuleRef module = getmodule(L);
    LLVMDisposeModule(module);
    return 0;
}

static int module_iterator(lua_State* L) {
    LLVMModuleRef module = getmodule(L);
    if (lua_isnil(L, 2)) {
        LLVMValueRef f = LLVMGetFirstFunction(module);
        const char* fname = LLVMGetValueName(f);
        lua_pushstring(L, fname);
        function_new(L, f);
    } else {
        const char* key = luaL_checkstring(L, 2);
        LLVMValueRef f = LLVMGetNamedFunction(module, key);
        LLVMValueRef fnext = LLVMGetNextFunction(f);
        if (fnext == NULL) {
            lua_pushnil(L);
            return 1;
        }
        const char* fnextname = LLVMGetValueName(fnext);
        lua_pushstring(L, fnextname);
        function_new(L, fnext);
    }
    return 2;
}

int module_pairs(lua_State* L) {
    lua_pushcfunction(L, module_iterator);
    lua_pushvalue(L, 1);
    lua_pushnil(L);
    return 3;
}

int module_index(lua_State* L) {
    LLVMModuleRef module = getmodule(L);
    const char* key = luaL_checkstring(L, 2);
    LLVMValueRef f = LLVMGetNamedFunction(module, key);
    if (f == NULL) {
        lua_pushnil(L);
    } else {
        function_new(L, f);
    }
    return 1;
}

int module_tostring(lua_State* L) {
    LLVMModuleRef module = getmodule(L);
    size_t size;
    lua_pushstring(L, LLVMGetModuleIdentifier(module, &size));
    return 1;
}
