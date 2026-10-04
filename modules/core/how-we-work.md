## How we work with Claude here

- **Plan before big changes.** Use plan mode for multi-file or architectural work, or whenever there are several valid approaches: explore and design first, then execute the agreed plan. Make small, well-scoped fixes directly.
- **Explore without flooding the context.** Hand broad discovery ("find every caller of X", "map the test layout") to the Explore subagent and keep its summary. Build understanding incrementally: Grep for entry points, then Read along the flow.
- **Interview before building in unfamiliar territory.** Ask the questions that surface hidden requirements (failure modes, invalidation, edge cases) before writing code.
- **Show, then test.** When a description is ambiguous, agree on 2–3 concrete input → output examples. Write or extend tests first, then iterate on the failures. Send interacting problems together in one message, and independent ones one at a time.
- **Don't grade your own homework.** The context that wrote a change is the worst one to review it. Run `/review`, which uses the independent `reviewer` subagent, before opening a PR.
- **Long sessions:** keep key facts (numbers, IDs, paths, decisions) in a scratchpad. Use `/compact` when the context fills with exploration output. To continue later, `/handoff` writes a summary for a fresh session; that is more reliable than resuming with stale tool results. When resuming, say which files changed.
- **Hooks enforce; this file guides.** Anything that must always hold is a hook or a CI gate. If a hook blocks you, that is the rule working.
