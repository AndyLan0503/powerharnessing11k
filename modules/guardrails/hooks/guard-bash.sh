#!/usr/bin/env bash
# Before a shell command: blocks destructive or guardrail-bypassing commands.
# Guard level: {{GUARD_LEVEL}}.
. "$(dirname "$0")/lib.sh"

LEVEL='{{GUARD_LEVEL}}'
DEFAULT_BRANCH='{{DEFAULT_BRANCH}}'
cmd=$(hook_command)
[ -n "$cmd" ] || exit 0

has() { printf '%s' "$cmd" | grep -Eq -- "$1"; }

# Always blocked, at every level.
has 'rm[[:space:]]+(-[[:alnum:]-]+[[:space:]]+)*(/|/\*|~/?|\$HOME/?)([[:space:]]|;|&|\||$)' &&
  hook_block "recursive delete of a root or home directory"
{{#unless PROFILE_SOLO}}
# The reason, if a `git push` in the command would update $DEFAULT_BRANCH on
# the remote: a refspec that names it, a push of every branch, or a push that
# names no branch (or HEAD) while it is checked out. Only a git that is the
# command word counts, so text such as `rg 'git push'` is not a push.
push_to_default() {
  local seg w state dir n implicit tags dst
  while IFS= read -r seg; do
    set -f
    # shellcheck disable=SC2086 # split into words on purpose
    set -- $seg
    set +f
    state=start dir=$(hook_cwd) n=0 implicit=1 tags=''
    for w in "$@"; do
      w=${w#[\"\']}
      w=${w%[\"\']}
      case $state in
        start)
          case $w in
            *=* | sudo | command | env | exec | nohup | time) ;;
            git) state=git ;;
            *) continue 2 ;;
          esac
          ;;
        git)
          case $w in
            -C) state=git-dir ;;
            -c) state=git-value ;;
            push) state=push ;;
            -*) ;;
            *) continue 2 ;; # another git command
          esac
          ;;
        git-dir)
          case $w in /*) dir=$w ;; *) dir=$dir/$w ;; esac
          state=git
          ;;
        git-value) state=git ;;
        push-value) state=push ;;
        push)
          case $w in
            --all | --branches | --mirror)
              echo "pushing every branch includes $DEFAULT_BRANCH; push one branch and open a PR"
              return 0
              ;;
            --tags) tags=1 ;;
            -o | --push-option | --repo | --receive-pack | --exec) state=push-value ;;
            -*) ;;
            *)
              # The first word is the remote; the rest are refspecs.
              n=$((n + 1))
              [ "$n" -gt 1 ] || continue
              implicit=''
              dst=${w#+}
              dst=${dst##*:}
              case $dst in
                "$DEFAULT_BRANCH" | "refs/heads/$DEFAULT_BRANCH")
                  echo "direct push to $DEFAULT_BRANCH; push a branch and open a PR"
                  return 0
                  ;;
                HEAD | @) implicit=1 ;;
              esac
              ;;
          esac
          ;;
      esac
    done
    case $state in push | push-value) ;; *) continue ;; esac
    [ -n "$implicit" ] || continue
    [ -z "$tags" ] || [ "$n" -gt 1 ] || continue
    if [ "$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null)" = "$DEFAULT_BRANCH" ]; then
      echo "you are on $DEFAULT_BRANCH, so this push goes straight to it; create a branch first (git switch -c <name>), push it, and open a PR"
      return 0
    fi
  done <<EOF
$(printf '%s' "$cmd" | tr ';&|()' '\n\n\n\n\n')
EOF
  return 1
}
reason=$(push_to_default) && hook_block "$reason"
{{/if}}
{{#if PROFILE_SOLO}}
: "$DEFAULT_BRANCH" # solo repo: pushing to the default branch is fine
{{/if}}

[ "$LEVEL" = relaxed ] && exit 0

# standard and strict
has 'git[[:space:]]+push([^;&|]*[[:space:]])(-f|--force)([[:space:]]|$)' &&
  hook_block "force-push rewrites shared history"
has '--no-verify' &&
  hook_block "--no-verify skips the checks that keep the repo healthy"
has '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da)?sh([[:space:]]|$)' &&
  hook_block "piping a download straight into a shell"
has 'chmod[[:space:]]+(-R[[:space:]]+)?0?777' &&
  hook_block "world-writable permissions"
# Example files are fine to touch, so take them out of the text first: naming
# one must not wave through a real .env elsewhere in the same command.
if printf '%s' "$cmd" |
  sed -E 's/\.env\.(example|sample|template|dist)([^[:alnum:]_.-]|$)/\2/g' |
  grep -Eq '(^|[[:space:]/])\.env(\.[[:alnum:]_.-]+)?([[:space:]]|;|&|\||$)'; then
  hook_block "reading or writing .env files; use .env.example for the shape"
fi

[ "$LEVEL" = strict ] || exit 0

# strict only
has 'git[[:space:]]+push[^;&|]*--force-with-lease' &&
  hook_block "force-push (even with lease) is human-only in strict mode"
has 'git[[:space:]]+reset[[:space:]]+--hard' &&
  hook_block "git reset --hard discards work; ask a human"
has 'git[[:space:]]+(clean[[:space:]]+-[[:alnum:]]*f|checkout[[:space:]]+--[[:space:]]+\.)' &&
  hook_block "discarding uncommitted changes"
has 'gh[[:space:]]+pr[[:space:]]+merge|gh[[:space:]]+api[^|;&]*/merge' &&
  hook_block "merging is a human decision"

exit 0
