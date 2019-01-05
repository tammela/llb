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

#ifndef _LLB_BB_H
#define _LLB_BB_H

extern int bb_new(lua_State*, LLVMBasicBlockRef);
extern int bb_pointer(lua_State*);
extern int bb_successors(lua_State*);
extern int bb_instructions(lua_State*);
extern int bb_tostring(lua_State*);

// TODO: WIP
extern int bb_store_instructions(lua_State*);
extern int bb_build_phi(lua_State*);
extern int bb_replace_between(lua_State*);
extern int bb_replace_loads(lua_State*);

#endif
