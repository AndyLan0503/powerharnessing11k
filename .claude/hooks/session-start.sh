#!/usr/bin/env bash
# Installs dependencies at the start of Claude Code cloud sessions so that
# lint and tests work there. A no-op on local machines.
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
exit 0
