#
# Makefile for building LLB
#

# Your platform. See PLATS for possible values.
PLAT= none

BIN= ../bin/

LLB_SO= llbc.so
LLB_DYLIB= llbc.dylib
TO_SO= $(BIN)/$(LLB_SO)
TO_DYLIB= $(BIN)/$(LLB_DYLIB)

# LLVM settings.
LLVM_INCLUDEDIR= -I$(shell llvm-config --includedir)
LLVM_CXXFLAGS= $(shell llvm-config --cxxflags)
LLVM_LDFLAGS= $(shell llvm-config --ldflags)
LLVM_LIBS= $(shell llvm-config --libs) $(shell llvm-config --system-libs)

# Compiler settings.
CC= gcc
CFLAGS= -O2 -fPIC -Wall -Werror -std=gnu99 $(LLVM_INCLUDEDIR)
LDFLAGS= $(LLVM_LDFLAGS) $(LLVM_LIBS) -llua

OBJS= function.o llbc.o module.o bb.o instruction.o

# Targets start here.
default: $(PLAT)

none:
	@echo "Please do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "    $(PLATS)"

macosx: $(OBJS)
	$(CC) -dynamiclib -undefined dynamic_lookup -o $(TO_DYLIB) $(OBJS) $(LDFLAGS)

linux: $(OBJS)
	$(CC) -shared -dl -Wl,-soname,$(LLB_SO) -o $(TO_SO) $(OBJS) $(LDFLAGS)

clean:
	$(RM) $(LLB_SO) $(LLB_DYLIB) $(OBJS)

# Binary dependencies.
bb.o: bb.c bb.h llbc.h
function.o: function.c function.h llbc.h bb.h
llbc.o: llbc.c llbc.h module.h bb.h function.h instruction.h
module.o: module.c module.h bb.h llbc.h
instruction.o: instruction.c instruction.h

# list targets that do not create files (but not all makes understand .PHONY)
.PHONY: none macosx linux clean

# (end of Makefile)
