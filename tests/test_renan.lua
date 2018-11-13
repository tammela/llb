require "setup"

local llb = require "llb"

local main = assert(llb.load_ir("aux/sum.ll")["main"])

local graph = main:bbgraph()
print(graph)
