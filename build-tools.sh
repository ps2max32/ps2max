#!/bin/bash
# Host tools: ps2client (our fork) -> tools/ps2client/bin/ps2client
# PS2 side (apps/, own repos): mxos, the kernel (EE on maxsdk, its IOP modules with clang
#            and lld, with mxlink's IOP module and mxshell for the card) -> build/apps/mxos,
#            mxboot -> build/apps/mxboot
set -e
cd "$(dirname "$0")"
make -C tools/ps2client
make -C apps/mxos all emu shell
# mxboot (the memory card boot program, its installer; kelftool): its KELF only
# with the keys (PS2KEYS.dat here, never committed)
if [ -f PS2KEYS.dat ]; then make -C apps/mxboot; else make -C apps/mxboot programs; fi
