#!/usr/bin/env bash
# Summarise the local agent audit log written by the harness hooks.
# Usage: .harness/report.sh [--days N] [--log FILE]
# Self-contained (bash, awk, date); nothing to install.
set -eu

days='' log=''
while [ $# -gt 0 ]; do
  case $1 in
    --days) days=${2:?--days needs a number}; shift ;;
    --log) log=${2:?--log needs a file}; shift ;;
    -h | --help)
      sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "report: unknown option $1" >&2; exit 1 ;;
  esac
  shift
done
[ -n "$log" ] || log="$(cd "$(dirname "$0")" && pwd)/logs/events.jsonl"

if [ ! -f "$log" ]; then
  echo "No agent activity recorded yet ($log). It fills as agents work in this repo."
  exit 0
fi

since=''
if [ -n "$days" ]; then
  since=$(date -u -d "-$days days" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null ||
    date -u -v-"$days"d +%Y-%m-%dT%H:%M:%SZ)
fi

echo "Agent activity${since:+ since $since}  ($log)"
echo
awk -v since="$since" '
  function field(name,    re) {
    re = "\"" name "\":\"([^\"\\\\]|\\\\.)*\""
    if (!match($0, re)) return ""
    return substr($0, RSTART + length(name) + 4, RLENGTH - length(name) - 5)
  }
  {
    ts = field("ts"); if (since != "" && ts < since) next
    kind = field("kind"); tool = field("tool"); sid = field("session_id")
    total++; kinds[kind]++
    if (sid != "") sessions[sid] = 1
    if (kind == "tool" && tool != "") { if (!(tool in tools)) nt++; tools[tool]++ }
    if (kind == "blocked") blocked[++nb] = ts "  " field("detail")
    if (kind == "check_failed") failed++
  }
  END {
    ns = 0; for (s in sessions) ns++
    printf "  Events: %d   Sessions: %d   Turns: %d   Blocked: %d   Failed checks: %d\n\n", total, ns, kinds["turn_end"], nb, failed
    if (nt > 0) {
      print "  Tool calls"
      for (t in tools) printf "    %-14s %d\n", t, tools[t] | "sort -k2 -nr"
      close("sort -k2 -nr")
      print ""
    }
    if (nb > 0) {
      print "  Most recent blocked actions"
      for (i = (nb > 10 ? nb - 9 : 1); i <= nb; i++) print "    " blocked[i]
    }
  }' "$log"
