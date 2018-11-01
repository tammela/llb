--
-- Lua binding for LLVM C API.
-- Copyright (C) 2018 Matheus Ambrozio, Pedro Tammela, Renan Almeida.
--
-- This file is part of lua-llvm-binding.
--
-- lua-llvm-binding is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
--
-- lua-llvm-binding is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with lua-llvm-binding. If not, see <http://www.gnu.org/licenses/>.
--

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
