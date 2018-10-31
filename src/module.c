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

#define newuserdata(L, type, value, tname) { \
    type *ptr = lua_newuserdata(L, sizeof(type)); \
    *ptr = value; \
    luaL_setmetatable(L, tname); \
} \

static void module_load_functions(lua_State*, LLVMModuleRef);

// static void newobject(lua_State *L, const char *tname, const luaL_Reg *funcs) {
//     luaL_newmetatable(L, tname);
//     lua_pushvalue(L, -1);
//     lua_setfield(L, -2, "__index");
//     luaL_setfuncs(L, funcs, 0);
//     lua_pop(L, 1);
// }

// int module_gc(lua_State *L) {
//     LLVMModuleRef module = *(LLVMModuleRef*)luaL_checkudata(L, 1, LLB_MODULE);
//     LLVMDisposeModule(module);
//     return 0;
// }

void module_new(lua_State *L, LLVMModuleRef module) {
    // creating the lua table for the module
    lua_newtable(L);

    // creating the user data for the module
    newuserdata(L, LLVMModuleRef, module, LLB_MODULE);

    // module.userdata = lua_module
    lua_setfield(L, -2, "userdata");

    module_load_functions(L, module);

    // module.functions = {function_name: {bb_name: bb_userdata}}
    lua_setfield(L, -2, "functions");    
}

static void module_load_functions(lua_State* L, LLVMModuleRef module) {
    // functions = {}
    lua_newtable(L);

    for (LLVMValueRef function = LLVMGetFirstFunction(module);
            function != NULL;
            function = LLVMGetNextFunction(function)) {
        // skiping functions without basic blocks
        if (LLVMCountBasicBlocks(function) == 0) {
            continue;
        }

        // getting the function's name to use as key
        const char* function_name = LLVMGetValueName(function);

        // basic_blocks = {}
        lua_newtable(L);

        for (LLVMBasicBlockRef bb = LLVMGetFirstBasicBlock(function);
                bb != NULL;
                bb = LLVMGetNextBasicBlock(bb)) {
            // basic_blocks[basic_block_name] = basic_block_userdata
            newuserdata(L, LLVMBasicBlockRef, bb, LLB_BASIC_BLOCK);
            lua_setfield(L, -2, LLVMGetValueName(LLVMBasicBlockAsValue(bb)));
        }

        // functions[function_name] = basic_blocks
        lua_setfield(L, -2, function_name);
    }
}
