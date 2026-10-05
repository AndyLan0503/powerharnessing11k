#!/usr/bin/env bash
# harness setup: the one entry point. Nothing to install, nothing on PATH.
#
#   git clone --depth=1 https://github.com/AndyLan0503/powerharnessing11k ~/.harness-workflow
#   cd ~/work/my-project            # an empty or existing repository
#   ~/.harness-workflow/setup.sh    # runs the setup wizard here
#
# Later, from the same project:
#   ~/.harness-workflow/setup.sh update     re-apply .harness/config
#   ~/.harness-workflow/setup.sh doctor     check for drift
#   ~/.harness-workflow/setup.sh help       everything else
# Upgrade harness itself with: git -C ~/.harness-workflow pull
set -eu
here=$(cd "$(dirname "$0")" && pwd)
case ${1:-} in
  '' | -*) exec "$here/bin/harness" configure "$@" ;;
  *) exec "$here/bin/harness" "$@" ;;
esac
