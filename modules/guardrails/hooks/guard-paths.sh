#!/usr/bin/env bash
# Before a file edit: blocks edits to secrets and, in strict mode, to files
# that define the guardrails themselves.
# Guard level: {{GUARD_LEVEL}}.
. "$(dirname "$0")/lib.sh"

LEVEL='{{GUARD_LEVEL}}'
path=$(hook_file)
[ -n "$path" ] || exit 0

rel=$(hook_rel "$path")
# A ".." that survives resolution goes through a directory that does not
# exist, so where the edit would land cannot be checked.
case "/$rel/" in */../*) hook_block "editing $path: paths through '..' cannot be checked; use the direct path" ;; esac
base=${rel##*/}

case $base in
  .env.example | .env.sample | .env.template | .env.dist) ;;
  .env | .env.*) hook_block "editing $rel: secret files are human-only" ;;
  *.pem | *.key | *.p12 | *.pfx | id_rsa* | id_ed25519*) hook_block "editing $rel: key material is human-only" ;;
esac

{{#if PROTECT_RAW_DATA}}
case $rel in
  data/raw/*) hook_block "editing $rel: raw data is immutable; write derived data to data/processed/ from a script" ;;
esac
{{/if}}
{{#if MOD_STUDY}}
case $rel in
  exercises/*) hook_block "editing $rel: this is the learner's own work; give hints or explanations instead" ;;
esac
{{/if}}

[ "$LEVEL" = strict ] || exit 0

case $rel in
  .github/workflows/* | .github/CODEOWNERS | CODEOWNERS | docs/CODEOWNERS | \
    .agents/hooks/* | scripts/ci/*{{PROTECTED_CASE}})
    hook_block "editing $rel: guardrail and CI configuration is human-only in strict mode"
    ;;
esac
exit 0
