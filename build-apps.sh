#!/bin/bash
# The apps built with maxsdk. Output goes to build/apps/.
# llvm_bench is not built here: it compares against ps2dev's gcc (see its README).
set -e
cd "$(dirname "$0")"
for app in model procgen quake1 quake2 quake3 descent3 hexen2 halflife duke3d doom njemu; do
  echo "=== $app"
  # its source lists look at the submodules
  [ $app = halflife ] || [ $app = duke3d ] || [ $app = njemu ] && make -C apps/$app submodules
  make -C apps/$app
done
echo "=== pcsx"
git -C apps/pcsx submodule update --init deps/libchdr deps/libretro-common
make -C apps/pcsx -f Makefile.maxsdk
