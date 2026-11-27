#!/bin/bash
# Configure and build the feature LLVM (clang, lld, compiler-rt builtins and the
# tools maxsdk uses) in build/toolchain/llvm/feature. Nothing is installed:
# maxsdk uses the build dir's bin/ directly.
set -e
cd "$(dirname "$0")"
toolchain/llvm/configure.sh feature
ninja -C build/toolchain/llvm/feature distribution llc llvm-mca llvm-mc
