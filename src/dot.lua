--
-- Lua binding for LLVM C API.
-- Copyright (C) 2018 Matheus Ambrozio, Pedro Tammela, Renan Almeida.
--
-- This file is part of llb.
--
-- llb is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
--
-- llb is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with llb. If not, see <http://www.gnu.org/licenses/>.
--

local dot = {}

function dot:bbgraph(bbgraph, name)
    local file = {}
    table.insert(file, 'digraph "CFG for ' .. name .. ' function" {')
    table.insert(file, '\tlabel="CFG for ' .. name .. ' function";\n')
    for _, node in ipairs(bbgraph) do
        table.insert(file, '\tNode' .. tostring(node.ref)
            .. ' [shape=record,label="{' .. tostring(node.ref) .. '}"];')
        for s in pairs(node.successors) do
            table.insert(file, '\tNode' .. tostring(node.ref)
                .. ' -> ' .. 'Node' .. tostring(s.ref) .. ';')
        end
    end
    table.insert(file, '}')
    return table.concat(file, '\n')
end

function dot:domgraph(dom, name)
    local file = {}
    table.insert(file, 'digraph "Dominance graph for ' .. name
        .. ' function" {')
    table.insert(file, '\tlabel="Dominance graph for ' .. name
        .. ' function";\n')
    for node, dominated in pairs(dom) do
        table.insert(file, '\tNode' .. tostring(node.ref)
            .. ' [shape=record,label="{' .. tostring(node.ref) .. '}"];')
        for d in pairs(dominated) do
            if node.ref ~= d.ref then
                table.insert(file, '\tNode' .. tostring(d.ref)
                    .. ' -> ' .. 'Node' .. tostring(node.ref) .. ';')
            end
        end
    end
    table.insert(file, '}')
    return table.concat(file, '\n')
end

function dot:idomgraph(idom, name)
    local file = {}
    table.insert(file, 'digraph "Imediate Dominance graph for ' .. name
        .. ' function" {')
    table.insert(file, '\tlabel="Imediate Dominance graph for ' .. name
        .. ' function";\n')
    for node, dominated in pairs(idom) do
        table.insert(file, '\tNode' .. tostring(node.ref)
            .. ' [shape=record,label="{' .. tostring(node.ref) .. '}"];')
        for d in pairs(dominated) do
            if node.ref ~= d.ref then
                table.insert(file, '\tNode' .. tostring(d.ref)
                    .. ' -> ' .. 'Node' .. tostring(node.ref) .. ';')
            end
        end
    end
    table.insert(file, '}')
    return table.concat(file, '\n')
end

return dot
