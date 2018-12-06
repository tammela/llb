#
# Makefile for testing LLB
#

TEST= @- lua -l setup

all: bugs tests

bugs:
	$(TEST) gc.lua


tests:
	$(TEST) test_set.lua
	$(TEST) test_functions.lua
	$(TEST) test_instructions.lua
