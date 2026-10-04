#!/usr/bin/env bash
# Install or upgrade harness.
#
# From a clone (works anywhere, including from a company fork):
#   git clone <harness repo or your fork> ~/.harness-workflow
#   ~/.harness-workflow/install.sh
#
# Remote one-liner (needs access to raw.githubusercontent.com):
#   curl -fsSL https://raw.githubusercontent.com/reclan-ai/harness-workflow/main/install.sh | bash
#
# Env overrides: HARNESS_REPO (git URL to clone, e.g. your fork), HARNESS_HOME
# (checkout, default ~/.harness-workflow), HARNESS_BIN (symlink dir, default
# ~/.local/bin), HARNESS_REF (branch or tag, default main).
set -eu

bin=${HARNESS_BIN:-$HOME/.local/bin}
here=''
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi

if [ -n "$here" ] && [ -x "$here/bin/harness" ] && [ -z "${HARNESS_REPO:-}" ]; then
  # Run from inside a checkout: install that checkout as-is. `harness
  # self-update` later pulls from its own origin (e.g. your company fork).
  home=$here
  echo "Installing harness from $home"
else
  command -v git >/dev/null 2>&1 || {
    echo "harness: git is required" >&2
    exit 1
  }
  repo=${HARNESS_REPO:-https://github.com/reclan-ai/harness-workflow.git}
  home=${HARNESS_HOME:-$HOME/.harness-workflow}
  ref=${HARNESS_REF:-main}
  if [ -d "$home/.git" ]; then
    echo "Updating $home"
    git -C "$home" fetch --quiet --tags origin
    if git -C "$home" rev-parse --quiet --verify "refs/remotes/origin/$ref" >/dev/null; then
      # A branch: stay on it, tracking origin, so `harness self-update` can pull.
      git -C "$home" checkout --quiet -B "$ref" --track "origin/$ref"
    else
      # A tag: a pinned release. Re-run this installer to move to another one.
      git -C "$home" checkout --quiet "$ref"
    fi
  else
    echo "Cloning $repo into $home"
    git clone --quiet --branch "$ref" "$repo" "$home"
  fi
fi

mkdir -p "$bin"
ln -sf "$home/bin/harness" "$bin/harness"
echo "Installed: $bin/harness ($("$home/bin/harness" version))"

case ":$PATH:" in
  *":$bin:"*) ;;
  *) echo "Add $bin to your PATH, e.g.: echo 'export PATH=\"$bin:\$PATH\"' >> ~/.zshrc" ;;
esac
echo
echo "Next: cd into a repository and run 'harness configure'."
