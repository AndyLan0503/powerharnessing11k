#!/usr/bin/env bash
# PreToolUse(Edit|Write|...): blocks edits to secrets and, in strict mode, to
# files that define the guardrails themselves.
# Guard level: standard.
. "$(dirname "$0")/lib.sh"

LEVEL='standard'
path=$(hook_field file_path)
[ -n "$path" ] || path=$(hook_field notebook_path)
[ -n "$path" ] || exit 0

root=$(hook_root)
rel=${path#"$root"/}
base=${rel##*/}

case $base in
  .env.example | .env.sample | .env.template | .env.dist) ;;
  .env | .env.*) hook_block "editing $rel: secret files are human-only" ;;
  *.pem | *.key | *.p12 | *.pfx | id_rsa* | id_ed25519*) hook_block "editing $rel: key material is human-only" ;;
esac


[ "$LEVEL" = strict ] || exit 0

case $rel in
  .github/workflows/* | .github/CODEOWNERS | CODEOWNERS | docs/CODEOWNERS | \
    .claude/settings.json | .claude/hooks/*)
    hook_block "editing $rel: guardrail and CI configuration is human-only in strict mode"
    ;;
esac
exit 0
