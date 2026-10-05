#!/usr/bin/env bash
# Agent guard: inspects a PR diff for the failure modes coding agents are most
# prone to.
#
# Env: BASE_SHA HEAD_SHA [HEAD_REF] [PR_BODY] [GUARD_MODE=warn|block] [DIFF_BUDGET=800]
# Writes a Markdown report to $GITHUB_STEP_SUMMARY (or stdout) and sets the
# step outputs agent=true|false and blocking=true|false.
set -euo pipefail

: "${BASE_SHA:?}" "${HEAD_SHA:?}"
MODE=${GUARD_MODE:-warn}
BUDGET=${DIFF_BUDGET:-800}
RANGE="$BASE_SHA...$HEAD_SHA"
SUMMARY=${GITHUB_STEP_SUMMARY:-/dev/stdout}
OUTPUT=${GITHUB_OUTPUT:-/dev/null}

TEST_PATH='(^|/)(tests?|__tests__|spec|specs)/|[._-](test|spec)\.[[:alnum:]]+$|_test\.go$|(^|/)test_[^/]*\.py$'
SKIP_MARK='\.(skip|only)\(|(^|[^[:alnum:]_])x(it|describe|test)\(|it\.todo\(|@pytest\.mark\.(skip|xfail)|@unittest\.skip|t\.Skip(Now|f)?\(|#\[ignore\]|@Disabled'
ASSERT='assert|expect\(|\.should|require\.|t\.(Error|Fatal)'
PROTECTED='^(\.github/workflows/|\.github/scripts/|\.github/CODEOWNERS$|CODEOWNERS$|\.claude/settings\.json$|\.claude/hooks/)'
MANIFESTS='(^|/)(package\.json|pyproject\.toml|requirements[^/]*\.txt|go\.mod|Cargo\.toml|Gemfile|pom\.xml|build\.gradle(\.kts)?)$'
LOCKFILES='(^|/)(package-lock\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?|uv\.lock|poetry\.lock|go\.sum|Cargo\.lock|Gemfile\.lock)$'
AGENT_TRAILER='^Co-Authored-By:.*(Claude|anthropic\.com|Copilot|Cursor|Codex|Devin|Jules|Aider)'
AGENT_BRANCH='^(claude|copilot|codex|cursor|devin|agent)/'

# ---- Is this agent work? ---------------------------------------------------
agent=false
why=''
if grep -Eiq "$AGENT_TRAILER|^noreply@anthropic\.com$" <<<"$(git log --format='%B%n%ae' "$BASE_SHA..$HEAD_SHA")"; then
  agent=true why='agent co-author trailer in commits'
elif grep -Eq "$AGENT_BRANCH" <<<"${HEAD_REF:-}"; then
  agent=true why="agent branch name (${HEAD_REF})"
elif grep -Eiq '\[x\][[:space:]]*Agent-authored' <<<"${PR_BODY:-}"; then
  agent=true why='PR template box "Agent-authored" is checked'
fi

# ---- Findings ---------------------------------------------------------------
findings=$(mktemp)
trap 'rm -f "$findings"' EXIT
add() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$findings"; } # severity check detail

deleted_tests=$(git diff --name-only --diff-filter=D "$RANGE" | grep -E "$TEST_PATH" || true)
[ -z "$deleted_tests" ] || add block "Deleted test files" "$(printf '%s' "$deleted_tests" | tr '\n' ' ')"

added=$(git diff -U0 "$RANGE" | grep -E '^\+[^+]' || true)
skips=$(printf '%s\n' "$added" | grep -Ec "$SKIP_MARK" || true)
[ "$skips" -eq 0 ] || add block "Skipped/focused tests added" "$skips line(s) add skip/only/xfail/ignore markers"

test_files=$(git diff --name-only "$RANGE" | grep -E "$TEST_PATH" || true)
if [ -n "$test_files" ]; then
  # shellcheck disable=SC2086
  tdiff=$(git diff -U0 "$RANGE" -- $test_files)
  removed_asserts=$(printf '%s\n' "$tdiff" | { grep -E '^-[^-]' || true; } | { grep -Eo "$ASSERT" || true; } | wc -l | tr -d ' ')
  added_asserts=$(printf '%s\n' "$tdiff" | { grep -E '^\+[^+]' || true; } | { grep -Eo "$ASSERT" || true; } | wc -l | tr -d ' ')
  if [ "$removed_asserts" -gt "$added_asserts" ]; then
    add block "Assertions removed" "test files lose $((removed_asserts - added_asserts)) assertion line(s) net"
  fi
fi

protected=$(git diff --name-only "$RANGE" | grep -E "$PROTECTED" || true)
[ -z "$protected" ] || add block "Protected paths changed" "$(printf '%s' "$protected" | tr '\n' ' ')"

size=$(git diff --numstat "$RANGE" | { grep -Ev "$LOCKFILES" || true; } | awk '{ a += ($1 == "-" ? 0 : $1); d += ($2 == "-" ? 0 : $2) } END { print a + d + 0 }')
[ "$size" -le "$BUDGET" ] || add warn "Large diff" "$size changed lines (budget $BUDGET, lockfiles excluded); consider splitting"

manifests=$(git diff --name-only "$RANGE" | grep -E "$MANIFESTS" || true)
[ -z "$manifests" ] || add warn "Dependency manifests changed" "$(printf '%s' "$manifests" | tr '\n' ' ')"

changed_am=$(git diff --name-only --diff-filter=AM "$RANGE")
big=''
while IFS= read -r f; do
  [ -n "$f" ] || continue
  bytes=$(git cat-file -s "$HEAD_SHA:$f" 2>/dev/null || echo 0)
  [ "$bytes" -le 5242880 ] || big="$big $f"
done <<EOF
$changed_am
EOF
[ -z "$big" ] || add warn "Large files (> 5 MB)" "keep data and model artifacts out of git:$big"
{{#if NOTEBOOK_CHECK}}

dirty_nb=''
while IFS= read -r f; do
  case $f in *.ipynb) ;; *) continue ;; esac
  if git show "$HEAD_SHA:$f" 2>/dev/null | grep -Eq '"output_type"[[:space:]]*:|"execution_count"[[:space:]]*:[[:space:]]*[0-9]'; then
    dirty_nb="$dirty_nb $f"
  fi
done <<EOF
$changed_am
EOF
[ -z "$dirty_nb" ] || add warn "Notebooks committed with outputs" "clear outputs before committing:$dirty_nb"
{{/if}}
{{#if MOD_ARTIFACTS}}

if git diff --name-only "$RANGE" | grep -qx 'artifacts.lock'; then
  add warn "Pinned artifacts changed" "artifacts.lock changed: the PR should say which data/models changed and why, and show results on the new hashes"
fi
{{/if}}
{{#if MOD_AGENTIC}}

changed_all=$(git diff --name-only "$RANGE")
if grep -q '^prompts/' <<<"$changed_all" && ! grep -q '^evals/' <<<"$changed_all"; then
  add warn "Prompts changed without eval changes" "attach before/after eval results or add eval cases (prompt-change skill)"
fi
{{/if}}

# ---- Report -----------------------------------------------------------------
blocking=false
if [ "$agent" = true ] && [ "$MODE" = block ] && grep -q '^block' "$findings"; then
  blocking=true
fi

{
  echo "## Agent guard"
  echo
  if [ "$agent" = true ]; then
    echo "**Agent-authored PR** ($why). Mode: \`$MODE\`."
  else
    echo "Not detected as agent-authored; findings are informational."
  fi
  echo
  if [ ! -s "$findings" ]; then
    echo "No findings. ✅"
  else
    echo "| | Check | Detail |"
    echo "|---|---|---|"
    while IFS="$(printf '\t')" read -r sev check detail; do
      icon='⚠️'
      if [ "$sev" = block ] && [ "$agent" = true ]; then icon='⛔'; fi
      echo "| $icon | $check | $detail |"
    done <"$findings"
    echo
    if [ "$agent" = true ] && [ "$MODE" != block ]; then
      echo "_Warn mode: nothing blocks the merge, but reviewers should look at each finding._"
    fi
  fi
} >>"$SUMMARY"

{
  echo "agent=$agent"
  echo "reason=$why"
  echo "blocking=$blocking"
  echo "block_count=$(grep -c '^block' "$findings" || true)"
  echo "warn_count=$(grep -c '^warn' "$findings" || true)"
} >>"$OUTPUT"
