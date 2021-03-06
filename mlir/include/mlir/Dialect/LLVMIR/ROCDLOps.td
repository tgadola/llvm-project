//===-- ROCDLOps.td - ROCDL IR dialect op definition file --*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This is the ROCDL IR operation definition file.
//
//===----------------------------------------------------------------------===//

#ifndef ROCDLIR_OPS
#define ROCDLIR_OPS

include "mlir/Dialect/LLVMIR/LLVMOpBase.td"
include "mlir/Interfaces/SideEffects.td"

//===----------------------------------------------------------------------===//
// ROCDL dialect definitions
//===----------------------------------------------------------------------===//

def ROCDL_Dialect : Dialect {
  let name = "rocdl";
  let cppNamespace = "ROCDL";
}

//===----------------------------------------------------------------------===//
// ROCDL op definitions
//===----------------------------------------------------------------------===//

class ROCDL_Op<string mnemonic, list<OpTrait> traits = []> :
  LLVM_OpBase<ROCDL_Dialect, mnemonic, traits> {
}

//===----------------------------------------------------------------------===//
// ROCDL special register op definitions
//===----------------------------------------------------------------------===//

class ROCDL_SpecialRegisterOp<string mnemonic,
    list<OpTrait> traits = []> :
  ROCDL_Op<mnemonic, !listconcat(traits, [NoSideEffect])>,
  Results<(outs LLVM_Type:$res)>, Arguments<(ins)> {
  string llvmBuilder = "$res = createIntrinsicCall(builder,"
    # "llvm::Intrinsic::amdgcn_" # !subst(".","_", mnemonic) # ");";
  let assemblyFormat = "attr-dict `:` type($res)";
}

class ROCDL_DeviceFunctionOp<string mnemonic, string device_function,
                             int parameter, list<OpTrait> traits = []> :
  ROCDL_Op<mnemonic, !listconcat(traits, [NoSideEffect])>,
  Results<(outs LLVM_Type:$res)>, Arguments<(ins)> {
  string llvmBuilder = "$res = createDeviceFunctionCall(builder, \""
  # device_function # "\", " # parameter # ");";
  let assemblyFormat = "attr-dict `:` type($res)";
}

//===----------------------------------------------------------------------===//
// Thread index and Block index

def ROCDL_ThreadIdXOp : ROCDL_SpecialRegisterOp<"workitem.id.x">;
def ROCDL_ThreadIdYOp : ROCDL_SpecialRegisterOp<"workitem.id.y">;
def ROCDL_ThreadIdZOp : ROCDL_SpecialRegisterOp<"workitem.id.z">;

def ROCDL_BlockIdXOp : ROCDL_SpecialRegisterOp<"workgroup.id.x">;
def ROCDL_BlockIdYOp : ROCDL_SpecialRegisterOp<"workgroup.id.y">;
def ROCDL_BlockIdZOp : ROCDL_SpecialRegisterOp<"workgroup.id.z">;

//===----------------------------------------------------------------------===//
// Thread range and Block range

def ROCDL_BlockDimXOp : ROCDL_DeviceFunctionOp<"workgroup.dim.x",
                                               "__ockl_get_local_size", 0>;

def ROCDL_BlockDimYOp : ROCDL_DeviceFunctionOp<"workgroup.dim.y",
                                               "__ockl_get_local_size", 1>;

def ROCDL_BlockDimZOp : ROCDL_DeviceFunctionOp<"workgroup.dim.z",
                                               "__ockl_get_local_size", 2>;

def ROCDL_GridDimXOp : ROCDL_DeviceFunctionOp<"grid.dim.x",
                                               "__ockl_get_global_size", 0>;

def ROCDL_GridDimYOp : ROCDL_DeviceFunctionOp<"grid.dim.y",
                                               "__ockl_get_global_size", 1>;

def ROCDL_GridDimZOp : ROCDL_DeviceFunctionOp<"grid.dim.z",
                                               "__ockl_get_global_size", 2>;

//===----------------------------------------------------------------------===//
// Synchronization primitives

def ROCDL_BarrierOp : ROCDL_Op<"barrier"> {
  string llvmBuilder = [{
    llvm::LLVMContext &llvmContext = builder.getContext();
    builder.CreateFence(llvm::AtomicOrdering::Release,
                        llvmContext.getOrInsertSyncScopeID("workgroup"));
    createIntrinsicCall(builder, llvm::Intrinsic::amdgcn_s_barrier);
    builder.CreateFence(llvm::AtomicOrdering::Acquire,
                        llvmContext.getOrInsertSyncScopeID("workgroup"));
  }];
  let assemblyFormat = "attr-dict";
}

#endif // ROCDLIR_OPS
