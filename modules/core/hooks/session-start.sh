#!/usr/bin/env bash
# Installs dependencies at the start of Claude Code cloud sessions so that
# lint and tests work there. A no-op on local machines.
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
{{#if INSTALL_CMD}}
log=$(mktemp)
if ! { {{INSTALL_CMD}}; } >"$log" 2>&1; then
  echo "session-start: dependency install failed. Last lines:" >&2
  tail -n 20 "$log" >&2
fi
rm -f "$log"
{{/if}}
exit 0
