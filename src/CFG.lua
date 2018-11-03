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
      BB[i] = {ref = ref, succs = {}, preds = {}}
      auxmap[ref:pointer()] = BB[i]
   end

   for _, bb in ipairs(BB) do
      local succs = BB.ref:succs()
      for _, succ in ipairs(succs) do
         local S = auxmap[succ]
         table.insert(BB.succs, S)
         table.insert(S.preds, BB)
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

function CFG:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   return o
end

return CFG
