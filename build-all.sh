#!/bin/bash
# Build everything in ps2max: LLVM, host tools, libraries, apps.
set -e
cd "$(dirname "$0")"
source ./envsetup.sh
[ -f "$PS2MAX_IOP_SDK/iop/include/irx.h" ] || { echo "ERROR: no ps2sdk IOP headers in $PS2MAX_IOP_SDK (build ps2dev first)"; exit 1; }
[ -d "$PS2MAX_IRX" ] || { echo "ERROR: no prebuilt IOP modules in $PS2MAX_IRX (build ps2dev first)"; exit 1; }
./build-llvm.sh
./build-libs.sh
./build-tools.sh
./build-apps.sh
