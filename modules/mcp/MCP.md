# MCP servers

Shared tool integrations for agents in {{PROJECT_NAME}}.

## Project scope (this repo, shared via git)

`.mcp.json` lists the servers the whole team uses. It ships with the GitHub MCP server. Credentials never go in the file: they are expanded from your environment, so each engineer sets them locally, e.g. in a shell profile:

```sh
export GITHUB_PERSONAL_ACCESS_TOKEN=...   # fine-grained, least privilege for this repo
```

Claude Code asks each person to approve project servers the first time. Run `/mcp` to check their status.

Guidelines:
- Prefer a maintained community or vendor server (GitHub, Jira, Sentry...) over building your own. Build custom servers only for team-specific workflows.
- Keep tool sets small and descriptions precise. An agent with too many similar tools picks the wrong one more often, so remove servers nobody uses.
- If agents keep using built-in tools (like Grep) where an MCP tool is better, improve that tool's description rather than adding prompt rules.
- Expose browsable catalogs (issue lists, schemas, doc trees) as MCP **resources** so agents don't need exploratory tool calls.

## User scope (just you)

Personal or experimental servers go in your user configuration, not this repo:

```sh
claude mcp add --scope user <name> ...
```

They are available alongside the project servers, and teammates are not affected.
