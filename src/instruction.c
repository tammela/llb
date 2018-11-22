/*
 * Lua binding for LLVM C API.
 * Copyright (C) 2018 Matheus Ambrozio, Pedro Tammela, Renan Almeida.
 *
 * This file is part of lua-llvm-binding.
 *
 * lua-llvm-binding is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * lua-llvm-binding is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with lua-llvm-binding. If not, see <http://www.gnu.org/licenses/>.
 */

#include <lauxlib.h>
#include <lua.h>
#include <stdlib.h>

#include <llvm-c/Core.h>

#include "instruction.h"
#include "llbcore.h"

int instruction_new(lua_State* L, LLVMValueRef instruction) {
    newuserdata(L, instruction, LLB_INSTRUCTION);
    return 1;
}

int instruction_label(lua_State* L) {
    LLVMValueRef inst = *(LLVMValueRef*)luaL_checkudata(L, 1, LLB_INSTRUCTION);
    lua_pushstring(L, LLVMGetValueName(inst));
    return 1;
}

int instruction_tostring(lua_State* L) {
    LLVMValueRef inst = *(LLVMValueRef*)luaL_checkudata(L, 1, LLB_INSTRUCTION);

    LLVMOpcode op = LLVMGetInstructionOpcode(inst);

    const char* inst_label = LLVMGetValueName(inst);

    char str[80] = "";
    switch (op) {
        default:
        case LLVMAlloca: {
            const char* alloca_type =
                LLVMPrintTypeToString(LLVMGetAllocatedType(inst));
            sprintf(str, "%%%s = alloca %s", inst_label, alloca_type);
            break;
        }
        case LLVMRet: {
            int num_operands = LLVMGetNumOperands(inst);
            if (num_operands == 0) {
                sprintf(str, "ret void");
            } else {
                LLVMValueRef operand = LLVMGetOperand(inst, 0);
                sprintf(str, "ret %s %%%s",
                    LLVMPrintTypeToString(LLVMTypeOf(operand)),
                    LLVMGetValueName(operand));
            }
            break;
        }
        case LLVMBr:
        case LLVMSwitch:
        case LLVMIndirectBr:
        case LLVMInvoke:
        case LLVMUnreachable:
        case LLVMAdd:
        case LLVMFAdd:
        case LLVMSub:
        case LLVMFSub:
        case LLVMMul:
        case LLVMFMul:
        case LLVMUDiv:
        case LLVMSDiv:
        case LLVMFDiv:
        case LLVMURem:
        case LLVMSRem:
        case LLVMFRem:
        case LLVMShl:
        case LLVMLShr:
        case LLVMAShr:
        case LLVMAnd:
        case LLVMOr:
        case LLVMXor:
        case LLVMLoad:
        case LLVMStore:
        case LLVMGetElementPtr:
        case LLVMTrunc:
        case LLVMZExt:
        case LLVMSExt:
        case LLVMFPToUI:
        case LLVMFPToSI:
        case LLVMUIToFP:
        case LLVMSIToFP:
        case LLVMFPTrunc:
        case LLVMFPExt:
        case LLVMPtrToInt:
        case LLVMIntToPtr:
        case LLVMBitCast:
        case LLVMAddrSpaceCast:
        case LLVMICmp:
        case LLVMFCmp:
        case LLVMPHI:
        case LLVMCall:
        case LLVMSelect:
        case LLVMUserOp1:
        case LLVMUserOp2:
        case LLVMVAArg:
        case LLVMExtractElement:
        case LLVMInsertElement:
        case LLVMShuffleVector:
        case LLVMExtractValue:
        case LLVMInsertValue:
        case LLVMFence:
        case LLVMAtomicCmpXchg:
        case LLVMAtomicRMW:
        case LLVMResume:
        case LLVMLandingPad:
        case LLVMCleanupRet:
        case LLVMCatchRet:
        case LLVMCatchPad:
        case LLVMCleanupPad:
            break;
    }

    lua_pushstring(L, str);

    return 1;
}
