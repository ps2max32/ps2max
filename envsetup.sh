#!/bin/bash
# Source this file: `source envsetup.sh`. Sets the paths the ps2max builds use.
# The Makefiles have the same defaults, so sourcing is only needed to override them
# or to get the tools on PATH.
#
# ps2max builds everything itself with its own LLVM (EE and IOP code alike). From
# ps2dev it takes only these, and nothing else:
#   PS2MAX_IOP_SDK  ps2sdk's IOP headers: iop/include, common/include
#   PS2MAX_IRX      the prebuilt IOP modules of ps2sdk (libsd.irx, audsrv.irx, ...)

export PS2MAX=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export PS2MAX_LLVM_SRC=$PS2MAX/toolchain/llvm/llvm-project
export PS2MAX_LLVM_BUILD=$PS2MAX/build/toolchain/llvm
export PS2MAX_LLVM_BIN=$PS2MAX_LLVM_BUILD/feature/bin
export PS2CLIENT=$PS2MAX/tools/ps2client/bin/ps2client

export PS2MAX_PS2DEV=${PS2MAX_PS2DEV:-$(cd "$PS2MAX/../ps2dev/install" 2>/dev/null && pwd)}
export PS2MAX_IOP_SDK=$PS2MAX_PS2DEV/ps2sdk
export PS2MAX_IRX=$PS2MAX_IOP_SDK/iop/irx

case ":$PATH:" in
  *":$PS2MAX_LLVM_BIN:"*) ;;
  *) export PATH=$PS2MAX_LLVM_BIN:$PS2MAX/tools/ps2client/bin:$PATH ;;
esac

echo "PS2MAX environment set to $PS2MAX"
