# ADR 0004: One standard for every PR; no authorship detection

- Status: accepted
- Date: 2026-10-05

## Context

The PR gate used to decide whether a pull request was "agent-authored" (a `Co-Authored-By` trailer, a branch prefix, or a PR-template checkbox) and treated the two groups differently: blocking-class findings could fail the gate only for agent PRs, and the working agreement told agents to keep the trailer so CI could recognise them. The weekly digest compared agent and human PRs.

Three problems:

- It forced an attribution convention on teams. Many teams do not want agent names in their history, and the generated repository should not dictate that.
- The detection was only as reliable as voluntary disclosure, so the comparison it fed was unreliable, and removing a trailer was a way to get lighter checks.
- A deleted test or a weakened assertion is the same risk whoever typed it.

## Decision

- The diff guard and the gate apply identical checks and identical blocking rules to every PR. The guard level alone decides whether blocking-class findings fail the gate (`strict`) or warn (`relaxed`, `standard`).
- Nothing detects, labels, or records who or what wrote a change. The scorecard has no authorship field, and the PR template has no agent-involvement section.
- The working agreement does not ask for a `Co-Authored-By` trailer. Teams that want one can add the convention themselves.
- The weekly digest reports all PRs together: volume, merges, reverts, gate scores, guard findings, overrides, and AI-review dismissals by pattern.
- Names follow the behaviour: the `diff-guard` module, `.github/scripts/diff-guard.sh`, and `.github/workflows/pr-digest.yml`.

## Consequences

- There is no lighter path through the gate, and nothing to gain from hiding how a change was made.
- Agent-versus-human statistics are gone. Agent behaviour is still visible where it can be observed directly: the local audit log of tool calls and blocked actions, and optional OpenTelemetry usage metrics.
- At the strict guard level, human PRs that delete or skip tests now fail the gate too, until fixed or overridden by another maintainer.
