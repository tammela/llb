#
# Makefile for building LLB
#

# Your platform. See PLATS for possible values.
PLAT= none

BIN= ../bin/

LLB_SO= core.so
LLB_DYLIB= core.dylib
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

OBJS= function.o core.o module.o bb.o instruction.o builder.o

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
	$(RM) $(LLB_SO) $(LLB_DYLIB) $(OBJS) *.o

# Binary dependencies.
bb.o: bb.c bb.h core.h
function.o: function.c function.h core.h bb.h
core.o: core.c core.h module.h bb.h function.h instruction.h
module.o: module.c module.h bb.h core.h builder.h
instruction.o: instruction.c instruction.h core.h
builder.o: builder.c builder.h core.h

# list targets that do not create files (but not all makes understand .PHONY)
.PHONY: none macosx linux clean

# (end of Makefile)
