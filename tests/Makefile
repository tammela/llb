#
# Makefile for testing LLB
#

TEST= @- lua -l setup
RM= rm -f

all: bugs tests

bugs:
	$(TEST) gc.lua

tests:
	$(TEST) test_set.lua
	$(TEST) test_module.lua
	$(TEST) test_llb.lua
	$(TEST) test_bbgraph.lua
	$(TEST) test_functions.lua

clean:
	$(RM) *.ll
	$(RM) *.bc
