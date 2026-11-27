#!/bin/sh
# Links this repo's git hooks (hooks/) into every project of the workspace.
# Run once after `repo init`/`repo sync`, and again when the manifest gains a project.
# Hooks that repo installs itself (pre-auto-gc) are kept.
set -e
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"
repo forall -c '
  hooks=$(git rev-parse --path-format=absolute --git-path hooks)
  mkdir -p "$hooks"
  for h in "'"$here"'"/hooks/*; do ln -sf "$h" "$hooks/$(basename "$h")"; done
'
echo "hooks linked into $(repo list | wc -l) projects"
