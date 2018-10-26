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

#include <llvm-c/Core.h>
#include <llvm-c/IRReader.h>
#include <lua.h>
#include <lauxlib.h>

#include "luallvm.h"
#include "core.h"

int coreobj(lua_State *L)
{
   luaL_getmetatable(L, LUALLVM_CORE);
   return 1;
}

int core_newmod(lua_State *L)
{
   const char *name = luaL_checkstring(L, 1);
   int hasctx = lua_isnoneornil(L, 2);
   LLVMModuleRef *module = lua_newuserdata(L, sizeof(LLVMModuleRef));
   luaL_setmetatable(L, LUALLVM_MODULE);
   if (hasctx) {
      LLVMContextRef ctx =
         *(LLVMContextRef *) luaL_checkudata(L, 2, LUALLVM_CONTEXT);
      *module = LLVMModuleCreateWithNameInContext(name, ctx);
   } else {
      *module = LLVMModuleCreateWithName(name);
   }
   return 1;
}

int core_newctx(lua_State *L)
{
   LLVMContextRef *p = lua_newuserdata(L, sizeof(LLVMContextRef));
   luaL_setmetatable(L, LUALLVM_CONTEXT);
   *p = LLVMContextCreate();
   return 1;
}

int core_parseIR(lua_State *L)
{
   LLVMContextRef ctx =
      *(LLVMContextRef *) luaL_checkudata(L, 1, LUALLVM_CONTEXT);
   LLVMMemoryBufferRef membuf =
      *(LLVMMemoryBufferRef *) luaL_checkudata(L, 2, LUALLVM_MEMBUF);
   LLVMModuleRef *mod = luaL_checkudata(L, 3, LUALLVM_MODULE);
   char *errmsg;
   if (LLVMParseIRInContext(ctx, membuf, mod, &errmsg) != 0) {
      lua_pushnil(L);
      lua_pushfstring(L, "[LLVM] %s", errmsg);
      return 2;
   }
   lua_pushboolean(L, 1);
   return 1;
}
