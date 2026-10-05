# Agent telemetry

{{#if OTEL_ENDPOINT}}
Claude Code sessions in this repo export OpenTelemetry metrics and events to `{{OTEL_ENDPOINT}}` (configured in `.claude/settings.json` → `env`).
{{/if}}
{{#unless OTEL_ENDPOINT}}
Telemetry export is **not configured**. To enable it, add the `CLAUDE_CODE_ENABLE_TELEMETRY` and `OTEL_*` variables to the `env` block of `.claude/settings.json` (see the monitoring docs below).
{{/if}}

## What you get

Claude Code emits metrics such as session count, lines of code changed, commits and PRs created, cost, token usage, and tool-permission decisions, plus events for prompts and tool results. See the [monitoring docs](https://code.claude.com/docs/en/monitoring-usage) for the full list.

## Auth headers

Never commit collector credentials. Each engineer sets them locally, for example in their shell profile:

```sh
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer <token>"
```

## Three layers of agent monitoring

| Layer | Source | Answers |
|---|---|---|
| Live usage | OpenTelemetry (this doc) | Cost, tokens, activity per engineer/repo |
| Local audit | `.agents/logs/events.jsonl` (`.agents/scripts/agent-report.sh`) | What tools ran, what was blocked |
| Outcomes | `diff-guard` and `pr-digest` workflows | Were PRs merged, reverted, flagged? |
