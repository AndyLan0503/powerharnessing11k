#!/usr/bin/env bash
# Installs dependencies at the start of cloud sessions so that lint and tests
# work there. A no-op on local machines, where the developer has done it.
. "$(dirname "$0")/lib.sh"

case $HOOK_AGENT in
  claude) [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0 ;;
  *) exit 0 ;;
esac
cd "$(hook_root)" || exit 0
{{#if INSTALL_CMD}}
log=$(mktemp)
if ! { {{INSTALL_CMD}}; } >"$log" 2>&1; then
  echo "session-start: dependency install failed. Last lines:" >&2
  tail -n 20 "$log" >&2
fi
rm -f "$log"
{{/if}}
exit 0
