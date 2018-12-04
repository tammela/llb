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

#ifndef _LLB_H
#define _LLB_H

// ==================================================
//
//  creates a new userdata and set it's mt to tname.
//  leaves the userdata on the stack.
//
// ==================================================

#define newuserdata(L, value, tname)                                    \
    do {                                                                \
        typeof(value)* ptr = lua_newuserdata(L, sizeof(typeof(value))); \
        *ptr = value;                                                   \
        luaL_setmetatable(L, tname);                                    \
    } while (0)

// ==================================================
//
//  metatable registry keys.
//
// ==================================================

#define LLB_MODULE ("__llb_module")
#define LLB_FUNCTION ("__llb_function")
#define LLB_BASICBLOCK ("__llb_basicblock")
#define LLB_INSTRUCTION ("__llb_instruction")

#endif
