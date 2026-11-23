#!/bin/bash
# Configure the build directory for one of the LLVM worktrees.
#
# Usage: ./configure.sh <feature|feature-assert|pr|tws|upstream>
#
# Build dirs in ps2max/build/toolchain/llvm/:
#   feature  : llvm-project  -> feature   (PS2EE cache + VU target, used by maxsdk; ps2max/build-llvm.sh)
#   feature-assert : llvm-project -> assert (VU target, assertions ON, for -debug-only)
#   pr       : wt/pr         -> pr        (assertions ON)
#   tws      : wt/tws        -> tws       (assertions ON)
#   upstream : wt/upstream   -> upstream  (assertions ON)

set -e

HERE=$(cd "$(dirname "$0")" && pwd)
BUILD_ROOT=$(cd "$HERE/../.." && pwd)/build/toolchain/llvm

COMMON=(
  -G Ninja
  -DCMAKE_BUILD_TYPE=Release
  -DLLVM_PARALLEL_LINK_JOBS=4
)
if command -v ccache >/dev/null; then
  COMMON+=(-DLLVM_CCACHE_BUILD=ON)
fi
if command -v ld.lld >/dev/null; then
  COMMON+=(-DLLVM_USE_LINKER=lld)
fi

case "$1" in
  feature)
    SRC=$HERE/llvm-project
    BUILD=$BUILD_ROOT/feature
    ARGS=(-C "$SRC/clang/cmake/caches/PS2EE.cmake" -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=VU)
    ;;
  feature-assert)
    SRC=$HERE/llvm-project
    BUILD=$BUILD_ROOT/assert
    ARGS=(-DLLVM_TARGETS_TO_BUILD=Mips -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=VU
          -DLLVM_ENABLE_PROJECTS=clang -DLLVM_ENABLE_ASSERTIONS=ON)
    ;;
  pr|tws|upstream)
    SRC=$HERE/wt/$1
    BUILD=$BUILD_ROOT/$1
    ARGS=(-DLLVM_TARGETS_TO_BUILD=Mips -DLLVM_ENABLE_PROJECTS=clang -DLLVM_ENABLE_ASSERTIONS=ON)
    ;;
  *)
    echo "Usage: $0 <feature|feature-assert|pr|tws|upstream>" >&2
    exit 1
    ;;
esac

mkdir -p "$BUILD"
cmake -S "$SRC/llvm" -B "$BUILD" "${COMMON[@]}" "${ARGS[@]}"
