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

LUALLVM_SO= llvm.so

# LLVM Specific
LLVM_INCLUDEDIR= -I$(shell llvm-config --includedir)
LLVM_LDFLAGS= $(shell llvm-config --ldflags)
LLVM_LIBS= $(shell llvm-config --libs) $(shell llvm-config --system-libs)

# Compiler settings
CC= gcc
CFLAGS= -O2 -fPIC -Wall -Werror -std=gnu99 $(LLVM_INCLUDEDIR)
LDFLAGS= $(LLVM_LDFLAGS) $(LLVM_LIBS) -l:liblua.a

OBJS= luallvm.o core.o membuf.o ctx.o module.o

all:
	$(MAKE) $(LUALLVM_SO)

clean:
	$(RM) $(LUALLVM_SO) $(OBJS)

$(LUALLVM_SO): $(OBJS)
	$(CC) -shared -dl -Wl,-soname,$(LUALLVM_SO) -o $@ $? $(LDFLAGS)

# binary dependencies
luallvm.o: luallvm.c luallvm.h core.h membuf.h ctx.h module.h
core.o: core.c luallvm.h core.h
membuf.o: membuf.c luallvm.h membuf.h
ctx.o: ctx.c luallvm.h ctx.h
module.o: module.c luallvm.h module.h
