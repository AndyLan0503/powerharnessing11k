# Agent telemetry

{{#if OTEL_ENDPOINT}}
Claude Code sessions in this repo export OpenTelemetry metrics and events to `{{OTEL_ENDPOINT}}` (configured in `.claude/settings.json` → `env`).
{{/if}}
{{#unless OTEL_ENDPOINT}}
Telemetry export is **not configured**. A maintainer can set `OTEL_ENDPOINT` in `.harness/config` and regenerate (see `.harness/README.md`).
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
| Local audit | `.harness/logs/events.jsonl` (`.harness/report.sh`) | What tools ran, what was blocked |
| Outcomes | `agent-guard` and `agent-digest` workflows | Were agent PRs merged, reverted, flagged? |
