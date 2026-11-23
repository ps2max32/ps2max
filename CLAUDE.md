# ps2max

LLVM based PS2 toolchain and SDK (maxsdk), and the projects built with it.

# layout
- `toolchain/llvm/` — LLVM with R5900/VU support, one worktree per role; see its CLAUDE.md.
- `libs/` — maxsdk, libgl, libmxm, picolibc, zlib, lwip (each its own git repo; lwip: upstream at STABLE-2_2_1_RELEASE, used by maxsdk's `iop/tcpip/mxnet`).
- `apps/` — projects built with maxsdk, plus `llvm_bench` (gcc vs clang).
- `tools/` — PC-side tools: `tools/ps2client/` (our ps2client), kelftool.
- `apps/mxos`, `apps/mxlink`, `apps/mxshell`, `apps/mxboot` — mx OS on the PS2, each its own repo (see "PS2 tools";
  the plan: `libs/maxsdk/docs/mx-os-apps-plan.md`).
- `build/` — all build output (`build/toolchain/llvm/<role>`, `build/libs/...`, `build/apps/...`,
  `build/apps/mxos`).

# building
- `./build-all.sh` builds everything: `build-llvm.sh` (feature LLVM), `build-tools.sh` (ps2client, mxlink),
  `build-libs.sh` (picolibc, maxsdk, libmxm), `build-apps.sh` (the maxsdk apps).
- `source envsetup.sh` exports the paths (`PS2MAX`, `PS2MAX_LLVM_SRC`, `PS2MAX_LLVM_BIN`, `PS2MAX_IRX`, ...)
  and puts the feature clang and ps2client on PATH. The Makefiles have the same defaults, so it is optional.
- The feature LLVM is used from its build dir (`build/toolchain/llvm/feature/bin`); nothing is installed.

# GitHub CI
- Each repo's `ps2max.deps` pins the commits it builds with (LLVM_REF, MAXSDK_REF, LIBGL_REF, ...); its
  CI (`ps2.yml`, calling `ps2max32/docker`'s `build.yml`) fetches exactly those. See `docker/README.md`.
- When a pushed change needs newer dependencies (a new maxsdk API, a new LLVM), push those first, then run
  `docker/scripts/deps.sh <repo dir>` and commit its `ps2max.deps` with the change. An LLVM without CI
  image: `deps.sh --dispatch` (about 2 hours).

# dependency rule: ps2max builds everything itself
- No gcc for PS2 code: EE and IOP builds use our own LLVM only (clang, ld.lld, llvm-objcopy). IOP modules
  build with maxsdk's `iop/Rules.mk` or `iop/iop.mk` (clang `--target=mipsel-none-irx`, which links with
  `ld.lld --irx`: it writes the IRX and its import/export tables from ILB files); a problem in LLVM is fixed in
  LLVM, not worked around with gcc.
- The only things ps2max may take from ps2dev are on the IOP side: ps2sdk's IOP headers (`PS2MAX_IOP_SDK`) and ps2sdk's prebuilt IOP modules
  (`PS2MAX_IRX`, e.g. libsd.irx, audsrv.irx).
- Exception: `apps/llvm_bench` uses ps2dev's EE and IOP gcc, newlib and ps2sdk, because it compares against gcc.
- Never add other references to `../ps2dev`, `PS2DEV` or `PS2SDK`; ps2dev never references ps2max.
  Check: `grep -rn ps2dev --exclude-dir=llvm_bench --exclude-dir=build ps2max` should only hit envsetup.sh,
  the IRX path in libs/maxsdk/Makefile, the PS2MAX_PS2DEV defaults in apps/mxos, apps/mxshell and apps/mxboot's Makefiles, and docs.
  No gcc: `grep -rln -e mipsel-none-elf- -e mips64r5900el-ps2-elf- --exclude-dir=llvm_bench --exclude-dir=build
  --exclude-dir=toolchain ps2max` should only hit docs (and third-party sources that are not built).

# porting games and apps
Design and rules (mx OS: what a program may and may not do, memory map, packaging): `libs/maxsdk/docs/mx-os.md`. Read it before porting.
Any change to how programs run (loader, kernel services, memory map, paths, pad combinations, packaging, libmx/libmxk) updates `mx-os.md` and `kernel.md` in the same commit.

# PS2 tools
- `apps/mxos` (the kernel, MXKERNEL.ELF, with a fallback for the host in ee/cmd.c), `apps/mxlink` (the host link:
  ps2link's IOP module and the app MXLINK.ELF, a service), `apps/mxshell` (the shell, MXSHELL.ELF: MXSHELL2, the Penumbra shell on libgl; the first shell is its branch `mxshell1`):
  `origin` ps2max32/mxos, ps2max32/mxlink, ps2max32/mxshell (public, our own repos: commit to master).
  `apps/mxboot` (the boot program, in `mc0:/MXBOOT/`): `origin` ps2max32/mxboot (public, since 2026-11-10).
- `tools/ps2client`: host side (`origin` rickgaiser/ps2client, `upstream` ps2dev/ps2client).
  Build: `make -C tools/ps2client` -> tools/ps2client/bin/ps2client.
- **The PS2 boots mxboot** (`apps/mxboot`, since 2026-11-07) from the memory card in slot 1: phase 1 (the
  system update KELF) starts `mc0:/MXBOOT/MXBOOT.ELF`, which starts what `mc0:/MXBOOT/BOOT.CFG` names:
  `mc0:/MXOS/MXKERNEL.ELF`. Never write the card in slot 2.
  There are two PS2s, each with its own card; the address belongs to the card (`mc0:/MXOS/IPCONFIG.DAT`:
  192.168.1.11 on the second card, without the file 192.168.1.10). The runner chooses a free PS2;
  name one with `PS2_IP=<address>` for runs that belong together (a kernel tried from RAM, anything on a
  card, one TV), and check `model=` in `ps2client status` before writing a card: the cards' kernels can differ.
- **The kernel (mxkernel) is what the PS2 runs** (`mc0:/MXOS/MXKERNEL.ELF`; before 2026-11-10 it was called mxlink,
  MXLINK.ELF): built in `apps/mxos`, ps2link's EE side rewritten on maxsdk, with ps2link's IOP module
  (`apps/mxlink/iop`, built with clang and lld) and protocol, so ps2client and the runner work as with
  ps2link. Build: `make -C apps/mxos all shell` (or `build-tools.sh`) -> build/apps/mxos/MXKERNEL.ELF
  (resident in the last MiB, 0x1F00000-0x1FFFFFF, its first half, the code, read-only for programs).
  - It loads ELFs itself (EE side), so **programs linked into VM (`MX_MEMORY=vm`) run directly**:
    `run.sh <app>.elf args`. They need the kernel: libmxk has no VM or file code of its own (libs/maxsdk/docs/kernel.md). On PCSX2: `make -C apps/mxos emu`, then that ELF with `PCSX2_EE=interp` and the program in host:mxload.txt.
  - **It runs MXOS programs only** (since 2026-11-11, mx OS plan step 2h-2): libmxk of kernel version 10 or
    later (`MX_TARGET=mxos` or `mxos-core`). A standalone ELF (libmx, `MX_TARGET=standalone`), ps2sdk's, an
    older libmxk or a loader (ps2link) is refused with a message ("not an MXOS program"); those are started
    by mxboot, a legacy loader or PCSX2's `-elf`. So the standalone mxboot-install.elf no
    longer starts on the PS2: card files are written with `mxboot-install-mxos.elf`.
  - To try a new kernel without installing: `run.sh build/apps/mxos/MXKERNEL.ELF 25`. A kernel ELF over the
    running one replaces it (it boots as after a reset of the kernel: services and shell again; the run
    reports a lost connection: expected); then the tests. A reset boots the installed one again. A crash
    while replacing shows on the screen and the old kernel goes on.
  - Programs return to the kernel when they end, no reboot: maxsdk's mx_exit (crash reports too) calls its
    return function. Back within 3 s
    with the IOP and network kept; a little over 4 s when the program loaded IOP modules or reset the IOP
    (the kernel resets it then). `exec` log lines count the returns. While a program runs, the host link cannot use
    host: itself: ping/dumpmem/dumpreg are refused then (as ps2link).
  - `ps2client status` says what it is doing: `state=ready|menu|running|starting returns=N status=<last exit>
    model=<SCPH-...> rom=<ROMVER> program=<path>`. mxlink's IOP module answers it alone, so **unlike ping it is safe during a run** and may
    be asked in a loop. The runner waits on it (a hello.elf run: 0.7 s); REBOOT_WAIT is only its maximum,
    15 s, the fixed wait for a plain ps2link.
  - With `mc0:/MXOS/SERVICES.CFG` (since kernel version 20: `mc0:/MXOS/MXLINK.ELF`, apps/mxlink/ee) it starts
    that service first: mxlink's app, which takes ps2client's commands but the reset (it ends the shell for them);
    while the app is not there (after a program that took all memory, until it is back) the kernel serves the
    reset, execee and the ping only.
  - With `mc0:/MXOS/MXSHELL.ELF` on the card it starts that shell (`state=menu`, which the runner counts as ready).
    A host command that needs host: stops the shell (ping and the runner's first run take a second longer);
    a host's program returns to the text screen (`state=ready`); `ps2client reset` goes back to the shell.
  - Its screen: status, network, last commands and errors (84 columns).
  - Install a new build through mxboot's one-shot (ask the user first): `mxboot-install-mxos copy
    host:MXKERNEL.ELF mc0:/MXOS/MXKERNEL.NEW`, `once mc0: mc?:/MXOS/MXKERNEL.NEW`, then the user presses reset (the
    next boot starts it, once). If it comes back, make it the default (`copy` it over
    `mc0:/MXOS/MXKERNEL.ELF`); if not, another reset boots the default again. Details: the skill.
- ps2link, the previous loader, is in `../ps2dev/tools/ps2link` (`origin` rickgaiser/ps2link,
  `upstream` ps2dev/ps2link): a ps2sdk program built with ps2dev's gcc; mxlink's iop/ came from its branch
  fio-write-stream. Build (needs ps2dev's envsetup.sh): `make -C ../ps2dev/tools/ps2link` -> bin/PS2LINK.ELF.
- The ps2-hw-test skill and `bench.sh run` use tools/ps2client/bin/ps2client, not ps2dev's.
  Never run `ps2client` directly for test runs; use the skill's runner (it takes the PS2 lock).
- Our ps2client additions: `status` (see mxlink), `serve` (files for the fast path alone, UDP 18197; it also runs beside execee and listen, off with PS2CLIENT_NO_FAST; branch fast-path), `ping` (is the kernel's host link up; EE side included), `-e <marker>` (exit at a console line
  containing it, exit status = its `status=N`), real exit statuses (64 usage, 69 not answering, 74 the loader
  closed the connection, 75 console port in use, 124 idle timeout before the marker), errors on stderr.
  Run `ps2client` without arguments for the list.
- ps2link's IOP module (so mxlink too) serves ONE host connection and a new one replaces it: any ps2client
  command except `status` (ping too) cuts off the host: files of a running program, which can crash the PS2.
  Never poll with ping in a loop (use status), never ping while another ps2client runs, and stop at the first sign of trouble (the kernel not coming back) and ask the
  user, instead of retrying.
- Test ps2client changes without hardware first: `tools/ps2client/tests/run-tests.sh` (fake ps2link in a user
  network namespace; add a test for each fix). Then check on the PS2 with one run at a time.
- These are our tools to improve: when running code on the PS2 fails, is flaky or slow, or is awkward to
  drive (e.g. probing whether mxlink is up, reset after a hang, output handling, transfer speed), fix it in
  ps2client/mxlink instead of adding workarounds to the runner scripts. Rebuild and re-test on hardware.
- The PS2 autoboots the kernel from its memory card; a rebuilt MXKERNEL.ELF (or MXLINK.ELF, the app) only takes
  effect after it is installed there. Ask the user before relying on a kernel or host link change.
- ps2client, ps2link: keep master equal to ps2dev master (`git fetch upstream`, fast-forward,
  `gh repo sync rickgaiser/<repo> -b master`); do our changes on branches. No commits or pushes without my
  approval.
