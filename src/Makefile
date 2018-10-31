#
# Lua binding for LLVM C API.
# Copyright (C) 2018 Matheus Ambrozio, Pedro Tammela, Renan Almeida.
#
# This file is part of lua-llvm-binding.
#
# lua-llvm-binding is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# lua-llvm-binding is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with lua-llvm-binding. If not, see <http://www.gnu.org/licenses/>.
#

LLB_SO= llb.so
LLB_DYLIB= llb.dylib

# LLVM Specific
LLVM_INCLUDEDIR= -I$(shell llvm-config --includedir)
LLVM_CXXFLAGS= $(shell llvm-config --cxxflags)
LLVM_LDFLAGS= $(shell llvm-config --ldflags)
LLVM_LIBS= $(shell llvm-config --libs) $(shell llvm-config --system-libs)

# Compiler settings
CC= gcc
CFLAGS= -O2 -fPIC -Wall -Werror -std=gnu99 $(LLVM_INCLUDEDIR)
LDFLAGS= $(LLVM_LDFLAGS) $(LLVM_LIBS) -llua

OBJS= llb.o module.o bb.o

none:
	@echo "invalid platform"

macosx:
	$(MAKE) $(LLB_DYLIB)

linux:
	$(MAKE) $(LLB_SO)

clean:
	$(RM) $(LLB_SO) $(LLB_DYLIB) $(OBJS)

$(LLB_SO): $(OBJS)
	$(CC) -shared -dl -Wl,-soname,$(LLB_SO) -o $@ $? $(LDFLAGS)

$(LLB_DYLIB): $(OBJS)
	$(CC) -dynamiclib -undefined dynamic_lookup -o $@ $? $(LDFLAGS)

# binary dependencies
llb.o: llb.c llb.h module.h
module.o: module.c module.h
bb.o: bb.c bb.h
