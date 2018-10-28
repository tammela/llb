package.cpath = package.cpath .. ";?.dylib"

local core = require "llvmcore"

local module, err = core.load_ir("ir.ll")
if err then
    print(err)
    return
end

print(module)
