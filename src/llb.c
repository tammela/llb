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

#include "core.h"

// static void newclass(lua_State *L, const char *tname, const luaL_Reg *funcs) {
//     luaL_newmetatable(L, tname);
//     lua_pushvalue(L, -1);
//     lua_setfield(L, -2, "__index");
//     luaL_setfuncs(L, funcs, 0);
//     lua_pop(L, 1);
// }

int luaopen_llb(lua_State *L) {
    // module
    // TODO

    // basic_block
    // TODO

    // const luaL_Reg lib_llvm[] = {
    //     {"Core", coreobj},
    //     {NULL, NULL}
    // };
    // newclass(L, LUALLVM_CORE, lib_core);

    // core
    const luaL_Reg lib_llb[] = {
        {"load_ir", core_load_ir},
        {"load_bitcode", core_load_bitcode},
        {"write_ir", core_write_ir},
        {"write_bitcode", core_write_bitcode},
        {NULL, NULL}
    };

    luaL_newlib(L, lib_llb);
    return 1;
}
