require "setup"

local llb = require "llb"

local main = assert(llb.load_ir("aux/sum.ll")["main"])

local bbgraph = main:bbgraph()
-- print(bbgraph)

main:domgraph()
