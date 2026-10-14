#!/usr/bin/env bash
# Prints a checksum of everything the recorded demo depends on: the tape and
# the code that draws the wizard's screens. `make demo` stores it next to the
# GIF, and the test suite compares, so a change that would make the GIF look
# different from the wizard fails until the demo is re-recorded.
set -eu
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"
# cksum is POSIX and prints the same "CRC SIZE" on Linux and macOS.
cat docs/demo/wizard.tape lib/ui.sh lib/wizard.sh | cksum
