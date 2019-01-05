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

#ifndef _LLB_INSTRUCTION_H
#define _LLB_INSTRUCTION_H

extern int instruction_new(lua_State*, LLVMValueRef);
extern int instruction_pointer(lua_State*);
extern int instruction_label(lua_State*);
extern int instruction_operands(lua_State*);
extern int instruction_usages(lua_State*);
extern int instruction_is_alloca(lua_State*);
extern int instruction_is_phi(lua_State*);
extern int instruction_is_store(lua_State*);
extern int instruction_is_load(lua_State*);
extern int instruction_replace_with(lua_State*);
extern int instruction_delete(lua_State*);
extern int instruction_equals(lua_State*);
extern int instruction_tostring(lua_State*);

#endif
