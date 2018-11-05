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

local CFG = {}

--
-- calculates all predecessors and sucessors of a function
--
local function calcps(f)
    local bbref = f:getBBs()
    local BBs = {}
    local auxmap = {}

    for i = 1, #bbref do
       local ref = bbref[i]
       BBs[i] = {ref = ref, succs = {}, preds = {}}
       auxmap[ref:pointer()] = BBs[i]
    end

    for _, bb in ipairs(BBs) do
       local succs = bb.ref:succs()
       for _, succ in ipairs(succs) do
          local S = auxmap[succ]
          table.insert(bb.succs, S)
          table.insert(S.preds, bb)
       end
    end

    return BBs
end

--
-- generates the CFG of a function
--
function CFG:fromfunc(f)
    self.BBs = calcps(f)
    -- TODO: generate graph
end

function CFG:string()
    local l = {}
    for _, v in pairs(self.BBs) do
        l[#l + 1] = '{ ' .. tostring(v.ref)
        if #v.succs ~= 0 then
            l[#l + 1] = ' { '
            for i = 1, #v.succs do
                if i ~= #v.succs then
                    l[#l + 1] = tostring(v.succs[i].ref) .. ' , '
                else
                    l[#l + 1] = tostring(v.succs[i].ref)
                end
            end
            l[#l + 1] = ' } '
        end
        l[#l + 1] = ' } '
    end
    return table.concat(l, "")
end

function CFG:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

return CFG
