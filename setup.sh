#!/usr/bin/env bash
# powerharnessing11k setup: the one entry point. Nothing to install, nothing on PATH.
#
#   git clone --depth=1 https://github.com/AndyLan0503/powerharnessing11k ~/powerharnessing11k
#   cd ~/work/my-project            # an empty or existing repository
#   ~/powerharnessing11k/setup.sh    # runs the setup wizard here
#
# It runs once per repository. Everything it writes is plain files the team
# owns and maintains from then on; the project never calls back into powerharnessing11k.
#
#   ~/powerharnessing11k/setup.sh --yes      non-interactive, profile defaults
#   ~/powerharnessing11k/setup.sh help       every option
set -eu
here=$(cd "$(dirname "$0")" && pwd)
case ${1:-} in
  '' | -*) exec "$here/bin/harness" configure "$@" ;;
  *) exec "$here/bin/harness" "$@" ;;
esac
