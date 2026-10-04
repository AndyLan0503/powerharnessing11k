# shellcheck shell=bash
MODULE_DESC="Team MCP servers in project-scoped .mcp.json (GitHub server; credentials via \${ENV} expansion, never committed)"

module_apply() {
  emit seed mcp.json .mcp.json
  emit file MCP.md docs/agents/MCP.md
}
