
function successors_predecessors(basic_blocks)
    for _, basic_block in pairs(basic_blocks) do
        local successors = {}
        for _, label in ipairs(basic_block.successors) do
            local successor = assert(basic_blocks[label])
            successors[successor.label] = true
            successor.predecessors[basic_block.label] = true
        end
        basic_block.successors = successors
    end
end

-- local basic_blocks = {
--     entry = {
--         label = "entry",
--         predecessors = {},
--         successors = {"l1", "l2"}
--     },
--     l1 = {
--         label = "l1",
--         predecessors = {},
--         successors = {"l3"}
--     },
--     l2 = {
--         label = "l2",
--         predecessors = {},
--         successors = {"l3"}
--     },
--     l3 = {
--         label = "l3",
--         predecessors = {},
--         successors = {}
--     }
-- }

-- successors_predecessors(basic_blocks)

-- for _, basic_block in pairs(basic_blocks) do
--     io.write(basic_block.label)
--     io.write("\n")

--     io.write("\t-- successors [")
--     for _, successor in ipairs(basic_block.successors) do
--         io.write(successor.label .. ", ")
--     end
--     io.write("]\n")

--     io.write("\t-- predecessors [")
--     for _, predecessor in ipairs(basic_block.predecessors) do
--         io.write(predecessor.label .. ", ")
--     end
--     io.write("]\n")
-- end
