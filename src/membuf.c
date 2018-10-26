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
#include <lua.h>
#include <lauxlib.h>

#include "luallvm.h"
#include "membuf.h"

int membufobj(lua_State *L)
{
   lua_newuserdata(L, sizeof(LLVMMemoryBufferRef));
   luaL_setmetatable(L, LUALLVM_MEMBUF);
   return 1;
}

int membuf_gc(lua_State *L)
{
   LLVMMemoryBufferRef p =
      *(LLVMMemoryBufferRef *) luaL_checkudata(L, 1, LUALLVM_MEMBUF);
   LLVMDisposeMemoryBuffer(p);
   return 0;
}

int membuf_len(lua_State *L)
{
   LLVMMemoryBufferRef p =
      *(LLVMMemoryBufferRef *) luaL_checkudata(L, 1, LUALLVM_MEMBUF);
   /* We are typecasting size_t to lua_Integer. */
   lua_pushinteger(L, LLVMGetBufferSize(p));
   return 1;
}

int membuf_fromfile(lua_State *L)
{
   LLVMMemoryBufferRef *p = luaL_checkudata(L, 1, LUALLVM_MEMBUF);
   const char *path = luaL_checkstring(L, 2);
   char *errmsg;
   if (LLVMCreateMemoryBufferWithContentsOfFile(path, p, &errmsg) != 0) {
      lua_pushnil(L);
      lua_pushfstring(L, "[LLVM] %s", errmsg);
      return 2;
   }
   lua_pushboolean(L, 1);
   return 1;
}
