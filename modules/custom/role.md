---
name: {{ITEM_NAME}}
description: "TODO(team): what this role does and when to delegate to it. Claude reads this to decide when to use the subagent."
# Keep the tool list as small as the role allows (read-only by default).
tools: Read, Grep, Glob
---

<!-- TODO(team): write this role's instructions, then delete this comment.

A role (subagent) runs in its own fresh context with only the tools above.
Describe:

1. Who it is and what it is responsible for (one paragraph).
2. What it receives: it does NOT see the main conversation, so say what the
   caller must pass in (files, refs, the goal).
3. What to check or produce, as a numbered list with concrete criteria.
4. What it must never do (e.g. edit files, run expensive jobs).
5. The output format: findings with file:line, severity, and a suggested fix,
   or "nothing found" in one line. -->

You are the {{ITEM_NAME}} for {{PROJECT_NAME}}.
