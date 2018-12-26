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

#include "bb.h"
#include "builder.h"
#include "core.h"
#include "function.h"
#include "instruction.h"
#include "module.h"

static int llb_error(lua_State* L, const char* err) {
    lua_pushnil(L);
    lua_pushfstring(L, "[LLVM] %s", err);
    return 2;
}

// ==================================================
//
// instantiates a new class on the lua registry
//
// ==================================================
static int llb_newclass(lua_State* L) {
    const char* tname = luaL_checkstring(L, 2);
    tname = lua_pushfstring(L, "__llb_%s", tname);
    if (lua_gettable(L, LUA_REGISTRYINDEX) == LUA_TNIL) {
        return luaL_error(L, "unknown class");
    }
    luaL_Reg* funcs = lua_touserdata(L, -1);
    lua_pushstring(L, tname);
    lua_setfield(L, 1, "__name");
    lua_pushvalue(L, 1);
    lua_setfield(L, 1, "__index");
    lua_pushvalue(L, 1);
    luaL_setfuncs(L, funcs, 0);
    lua_setfield(L, LUA_REGISTRYINDEX, tname);
    return 0;
}

// ==================================================
//
//  creates a llvm module from a .ll file
//
// ==================================================
static int llb_load_ir(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    LLVMContextRef ctx = LLVMContextCreate();
    char* err;

    LLVMMemoryBufferRef memory_buffer;
    if (LLVMCreateMemoryBufferWithContentsOfFile(path, &memory_buffer, &err)) {
        return llb_error(L, err);
    }

    LLVMModuleRef module;
    if (LLVMParseIRInContext(ctx, memory_buffer, &module, &err)) {
        return llb_error(L, err);
    }

    return module_new(L, module);
}

// ==================================================
//
//  creates a llvm module from a .bc file
//
// ==================================================
static int llb_load_bitcode(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    char* err;

    LLVMMemoryBufferRef memory_buffer;
    if (LLVMCreateMemoryBufferWithContentsOfFile(path, &memory_buffer, &err)) {
        return llb_error(L, err);
    }

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
static int llb_write_bitcode(lua_State* L) {
    LLVMModuleRef module = *(LLVMModuleRef*)luaL_checkudata(L, 1, LLB_MODULE);
    const char* path = luaL_checkstring(L, 2);

    if (LLVMWriteBitcodeToFile(module, path)) {
        return llb_error(L, "could not write bitcode to the output file");
    }

    return 0;
}

// clang-format off
struct luaL_Reg module_mt[] = {
    {"dispose", module_dispose},
    {"get_builder", module_get_builder},
    {"__index", module_index},
    {"__pairs", module_pairs},
    {"__tostring", module_tostring},
    {NULL, NULL}
};

struct luaL_Reg func_mt[] = {
    {"basic_blocks", function_basic_blocks},
    {"__tostring", function_tostring},
    {NULL, NULL}
};

struct luaL_Reg bb_mt[] = {
    {"pointer", bb_pointer},
    {"successors", bb_successors},
    {"instructions", bb_instructions},
    {"__tostring", bb_tostring},
    {NULL, NULL}
};

struct luaL_Reg inst_mt[] = {
    {"label", instruction_label},
    {"pointer", instruction_pointer},
    {"operands", instruction_operands},
    {"usages", instruction_usages},
    {"is_alloca", instruction_is_alloca},
    {"is_store", instruction_is_store},
    {"is_load", instruction_is_load},
    {"replace_with", instruction_replace_with},
    {"delete", instruction_delete},
    {"__tostring", instruction_tostring},
    {NULL, NULL}
};

struct luaL_Reg builder_mt[] = {
    {"prune_alloca", builder_prune_alloca},
    {"position_builder", builder_position_builder},
    {"build_phi", builder_build_phi},
    {NULL, NULL}
};
// clang-format on

// ==================================================
//
//  luaopen
//
// ==================================================
int luaopen_core(lua_State* L) {
    // clang-format off
    const luaL_Reg lib_llb[] = {
        {"load_ir", llb_load_ir},
        {"load_bitcode", llb_load_bitcode},
        {"write_bitcode", llb_write_bitcode},
        {"newclass", llb_newclass},
        {NULL, NULL}
    };
    // clang-format on

    lua_pushlightuserdata(L, module_mt);
    lua_pushlightuserdata(L, func_mt);
    lua_pushlightuserdata(L, bb_mt);
    lua_pushlightuserdata(L, inst_mt);
    lua_pushlightuserdata(L, builder_mt);

    lua_setfield(L, LUA_REGISTRYINDEX, LLB_BUILDER);
    lua_setfield(L, LUA_REGISTRYINDEX, LLB_INSTRUCTION);
    lua_setfield(L, LUA_REGISTRYINDEX, LLB_BASICBLOCK);
    lua_setfield(L, LUA_REGISTRYINDEX, LLB_FUNCTION);
    lua_setfield(L, LUA_REGISTRYINDEX, LLB_MODULE);

    luaL_newlib(L, lib_llb);
    return 1;
}
