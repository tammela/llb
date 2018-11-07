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

#include <llvm-c/BitReader.h>
#include <llvm-c/BitWriter.h>
#include <llvm-c/Core.h>
#include <llvm-c/IRReader.h>

#include "llbcore.h"
#include "module.h"
#include "bb.h"
#include "function.h"

static void newclass(lua_State *L, const char *tname, const luaL_Reg *funcs) {
    luaL_newmetatable(L, tname);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, funcs, 0);
    lua_pop(L, 1);
}

static int llb_error(lua_State *L, const char *err) {
    lua_pushnil(L);
    lua_pushfstring(L, "[LLVM] %s", err);
    return 2;
}

// ==================================================
//
//  creates a llvm module from a .ll file
//
// ==================================================

static int llb_load_ir(lua_State *L) {
    const char *path = luaL_checkstring(L, 1);
    char *err;
    LLVMContextRef ctx = LLVMContextCreate();

    // creating the memory buffer
    LLVMMemoryBufferRef memory_buffer;
    if (LLVMCreateMemoryBufferWithContentsOfFile(path, &memory_buffer, &err)) {
        return llb_error(L, err);
    }

    // creating the module
    LLVMModuleRef module;
    if (LLVMParseIRInContext(ctx, memory_buffer, &module, &err)) {
        // FIXME: this is causing an error
        // LLVMDisposeMemoryBuffer(memory_buffer);
        return llb_error(L, err);
    }
    // LLVMDisposeMemoryBuffer(memory_buffer);

    return module_new(L, module);
}

// ==================================================
//
//  creates a llvm module from a .bc file
//
// ==================================================

static int llb_load_bitcode(lua_State *L) {
    const char *path = luaL_checkstring(L, 1);
    char *err;

    // reading the file from path
    LLVMMemoryBufferRef memory_buffer;
    if (LLVMCreateMemoryBufferWithContentsOfFile(path, &memory_buffer, &err)) {
        return llb_error(L, err);
    }

    // creating the module
    LLVMModuleRef module;
    if (LLVMParseBitcode(memory_buffer, &module, &err)) {
        LLVMDisposeMemoryBuffer(memory_buffer);
        return llb_error(L, err);
    }
    LLVMDisposeMemoryBuffer(memory_buffer);

   return module_new(L, module);
}

// ==================================================
//
//  writes a llvm module to a .bc file
//
// ==================================================

static int llb_write_bitcode(lua_State *L) {
    LLVMModuleRef module = *(LLVMModuleRef*)luaL_checkudata(L, 1, LLB_MODULE);
    const char *path = luaL_checkstring(L, 2);

    if (LLVMWriteBitcodeToFile(module, path)) {
        return llb_error(L, "could not write bitcode to the output file");
    }

    return 0;
}

// ==================================================
//
//  luaopen
//
// ==================================================

int luaopen_llbcore(lua_State* L) {
    const luaL_Reg lib_llb[] = {
        {"load_ir", llb_load_ir},
        {"load_bitcode", llb_load_bitcode},
        {"write_bitcode", llb_write_bitcode},
        {NULL, NULL}
    };

    const struct luaL_Reg module_mt[] = {
        {"__gc", module_gc},
        {"__index", module_index},
        {"__pairs", module_pairs},
        {NULL, NULL}
    };

    const struct luaL_Reg func_mt[] = {
        {"getBBs", function_getbb},
        {NULL, NULL}
    };

    const struct luaL_Reg bb_mt[] = {
        {"pointer", bb_pointer},
        {"succs", bb_succs},
        {"__tostring", bb_tostring},
        {NULL, NULL}
    };

    newclass(L, LLB_MODULE, module_mt);
    newclass(L, LLB_FUNCTION, func_mt);
    newclass(L, LLB_BASICBLOCK, bb_mt);

    luaL_newlib(L, lib_llb);
    return 1;
}
