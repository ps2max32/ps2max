#!/bin/bash
# Libraries, in dependency order. Output goes to build/libs/.
set -e
cd "$(dirname "$0")"
make -C libs/maxsdk picolibc
make -C libs/maxsdk lib libc
make -C libs/maxsdk/iop
make -C libs/libmxm
