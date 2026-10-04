---
description: Independent review of the current changes by the reviewer subagent (fresh context)
argument-hint: "[base branch or ref, default {{DEFAULT_BRANCH}}]"
---

Delegate this review to the `reviewer` subagent so it runs in a fresh context, without the reasoning that produced the change.

Base ref: $ARGUMENTS (if empty, use `{{DEFAULT_BRANCH}}`).

Tell the subagent the base ref and a one-paragraph statement of what the change is supposed to do. When it returns, relay its findings unchanged, grouped by severity. Don't start fixing anything until the user says which findings to address.
