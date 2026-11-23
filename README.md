# ps2max

Manifest for the ps2max workspace (LLVM based PS2 toolchain, maxsdk and the projects built with it),
for Google's [`repo`](https://gerrit.googlesource.com/git-repo) tool.

    mkdir ps2max && cd ps2max
    repo init -u https://github.com/ps2max32/ps2max
    repo sync

`repo sync` checks out every project listed in `default.xml` and links the build scripts and docs
(`build-all.sh`, `envsetup.sh`, `CLAUDE.md`, ...) from this repo into the workspace root. Then are created by hand.
`CLAUDE.md` for building: `./build-all.sh`.

Notes:
- The LLVM extra worktrees (`toolchain/llvm/wt/*`) are not managed by `repo`; are created by hand.
- Some projects (apps/model, apps/openlara, apps/pcsx, apps/procgen, libs/libmxm) have no remote yet and are not listed.
- Projects follow a branch (usually `ps2` for ports, `master` for the rest), not a pinned commit.
  `repo manifest -r -o pinned.xml` records the exact commits of a workspace.
