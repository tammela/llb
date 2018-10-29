package.cpath = package.cpath .. ";?.dylib"

local core = require "llvmcore"

local module, err = core.load_ir("ir.ll")
if err then
    print(err)
    return
end

local err = core.write_bitcode(module, "bitcode.bc")
if err then
    print(err)
    return
end
