#!/usr/bin/env bash
# Install or upgrade harness:
#   curl -fsSL https://raw.githubusercontent.com/reclan-ai/harness-workflow/main/install.sh | bash
#
# Env overrides: HARNESS_HOME (checkout, default ~/.harness-workflow),
# HARNESS_BIN (symlink dir, default ~/.local/bin), HARNESS_REF (default main),
# HARNESS_REPO (git URL).
set -eu

repo=${HARNESS_REPO:-https://github.com/reclan-ai/harness-workflow.git}
home=${HARNESS_HOME:-$HOME/.harness-workflow}
bin=${HARNESS_BIN:-$HOME/.local/bin}
ref=${HARNESS_REF:-main}

command -v git >/dev/null 2>&1 || {
  echo "harness: git is required" >&2
  exit 1
}

if [ -d "$home/.git" ]; then
  echo "Updating $home"
  git -C "$home" fetch --quiet --depth 1 origin "$ref"
  git -C "$home" checkout --quiet FETCH_HEAD
else
  echo "Cloning harness into $home"
  git clone --quiet --depth 1 --branch "$ref" "$repo" "$home"
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
