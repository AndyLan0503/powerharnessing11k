# shellcheck shell=bash
MODULE_DESC="Team MCP servers in each agent's project config (GitHub server; credentials come from the environment, never committed)"

module_apply() {
  settings_mcp_http github https://api.githubcopilot.com/mcp/ GITHUB_PERSONAL_ACCESS_TOKEN
  emit file MCP.md docs/agents/MCP.md
}
