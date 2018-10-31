require "setup"

local llb = require "llb"

-- FIXME: not giving errors when trying to load bad .ll files
-- local m = llb.load_ir("aux/ir_1.ll")

local m = llb.load_ir("aux/sum.ll")

assert(type(m) == "table", "type: " .. type(m))
assert(type(m.userdata) == "userdata", "type: " .. type(m.userdata))
assert(type(m.functions) == "table", "type: " .. type(m.functions))

for function_name, basic_blocks in pairs(m.functions) do
    assert(type(function_name) == "string")
    for basic_block_label, basic_block in pairs(basic_blocks) do
        assert(type(basic_block_label) == "string")
        assert(type(basic_block) == "table")
        assert(type(basic_block.label) == "string")
        assert(type(basic_block.userdata) == "userdata")
    end
end
