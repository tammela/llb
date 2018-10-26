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

#include "luallvm.h"
#include "core.h"
#include "membuf.h"
#include "ctx.h"
#include "module.h"

static void newclass(lua_State *L, const char *tname, const luaL_Reg *funcs)
{
   luaL_newmetatable(L, tname);
   lua_pushvalue(L, -1);
   lua_setfield(L, -2, "__index");
   luaL_setfuncs(L, funcs, 0);
   lua_pop(L, 1);
}

int luaopen_llvm(lua_State *L)
{
   const luaL_Reg luallvm_lib[] = {
      {"Core", coreobj},
      {"MemoryBuffer", membufobj},
      {NULL, NULL}
   };

   /* core object methods */
   const luaL_Reg mt_coreobj[] = {
      {"ModuleCreate", core_newmod},
      {"ContextCreate", core_newctx},
      {"ParseIRinContext", core_parseIR},
      {NULL, NULL}
   };

   /* membuf object methods */
   const luaL_Reg mt_membufobj[] = {
      {"CreateWithContentsOfFile", membuf_fromfile},
      {"__gc", membuf_gc},
      {"__len", membuf_len},
      {NULL, NULL}
   };

   /* module object methods */
   const luaL_Reg mt_moduleobj[] = {
      {"__gc", module_gc},
      {NULL, NULL}
   };

   /* context object methods */
   const luaL_Reg mt_ctxobj[] = {
      {"__gc", ctx_gc},
      {NULL, NULL}
   };

   newclass(L, LUALLVM_CORE, mt_coreobj);
   newclass(L, LUALLVM_MEMBUF, mt_membufobj);
   newclass(L, LUALLVM_MODULE, mt_moduleobj);
   newclass(L, LUALLVM_CONTEXT, mt_ctxobj);
   luaL_newlib(L, luallvm_lib);
   return 1;
}
