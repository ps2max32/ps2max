# ps2max

Manifest for the ps2max workspace (LLVM based PS2 toolchain, maxsdk and the projects built with it),
for Google's [`repo`](https://gerrit.googlesource.com/git-repo) tool.

    mkdir ps2max && cd ps2max
    repo init -u https://github.com/ps2max32/ps2max
    repo sync

`repo sync` checks out every project listed in `default.xml` and links the build scripts and docs
(`build-all.sh`, `envsetup.sh`, `CLAUDE.md`, ...) from this repo into the workspace root. Then see
`CLAUDE.md` for building: `./build-all.sh`. Then link the git hooks into every project once
(again after the manifest gains a project): `.manifest-root/install-hooks.sh`.

## Branches

The manifest's revision, the branch on the remote and the local branch have the same name.

| Kind | Remote | Branch |
|---|---|---|
| Our own code (maxsdk, libgl, mxos, mxlink, mxshell, mxboot, neutrino, ...) | ps2max32 | `master` |
| Ports of other projects (the games, emulators) | a fork on ps2max32 | `ps2` = our work, `master` = the upstream project's |
| Third-party code we do not change (lwip, mbedtls, picolibc, zlib, kelftool) | the upstream project | a tag or commit, never local changes (a change needs a fork first) |
| Work in progress | the project's remote | a feature branch: pushed, merged into the manifest's branch, then deleted |

- `repo sync` leaves a project on a detached HEAD. Before committing: `repo start <branch> <project>`
  (`repo start master libs/maxsdk`, `repo start ps2 apps/doom`). The pre-commit hook refuses a commit on a
  detached HEAD.
- A branch that is worked on for a while (as neutrino's `maxsdk` before it goes into `master`) may be the
  manifest's revision meanwhile; it goes back to `master` when it is merged.
- Push work that is kept; no local-only branches as a stash. A branch merged into the manifest's branch is
  deleted locally and on the remote.
- A git checkout in the workspace belongs in the manifest, with its own remote.

Notes:
- The LLVM extra worktrees (`toolchain/llvm/wt/*`) are not managed by `repo`: create them by hand.
- Some projects (apps/model, apps/openlara, apps/pcsx, apps/procgen, libs/libmxm) have no remote yet and are not listed.
- Projects follow a branch (usually `ps2` for ports, `master` for the rest), not a pinned commit.
  `repo manifest -r -o pinned.xml` records the exact commits of a workspace.
