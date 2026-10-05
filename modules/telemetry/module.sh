# shellcheck shell=bash
MODULE_DESC="Claude Code OpenTelemetry export (cost, tokens, sessions, tool decisions) to your collector"

module_apply() {
  emit file docs/TELEMETRY.md docs/agents/TELEMETRY.md
  if [ -n "$HV_OTEL_ENDPOINT" ]; then
    settings_agent claude env CLAUDE_CODE_ENABLE_TELEMETRY 1
    settings_agent claude env OTEL_METRICS_EXPORTER otlp
    settings_agent claude env OTEL_LOGS_EXPORTER otlp
    settings_agent claude env OTEL_EXPORTER_OTLP_PROTOCOL grpc
    settings_agent claude env OTEL_EXPORTER_OTLP_ENDPOINT "$HV_OTEL_ENDPOINT"
    settings_agent claude env OTEL_RESOURCE_ATTRIBUTES "service.name=claude-code,repo=$HV_PROJECT_NAME"
  fi
}
