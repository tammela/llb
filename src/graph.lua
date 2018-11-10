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

local smt = require "set_mt"

local graph = {}

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
       setmetatable(BBs[i].succs, smt)
       setmetatable(BBs[i].preds, smt)
       auxmap[ref:pointer()] = BBs[i]
    end

    for _, bb in ipairs(BBs) do
       local succs = bb.ref:succs()
       for _, succ in ipairs(succs) do
          local S = auxmap[succ]
          bb.succs[S] = S
          S.preds[bb] = bb
       end
    end

    return BBs
end

function graph:predsucc(obj)
    local BBs = calcps(obj)
    if #BBs == 0 then
       return nil, "calculation failed"
    end
    self.BBs = BBs
    return true
end

function graph.__tostring()
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

function graph:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

return graph
