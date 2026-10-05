## How we work with coding agents here

- **Plan before big changes.** For multi-file or architectural work, or whenever there are several valid approaches, explore and design first (in plan mode, if your agent has one), then execute the agreed plan. Make small, well-scoped fixes directly.
- **Explore without flooding the context.** Hand broad discovery ("find every caller of X", "map the test layout") to a subagent and keep its summary. Build understanding incrementally: search for entry points, then read along the flow.
- **Interview before building in unfamiliar territory.** Ask the questions that surface hidden requirements (failure modes, invalidation, edge cases) before writing code.
- **Show, then test.** When a description is ambiguous, agree on 2–3 concrete input → output examples. Write or extend tests first, then iterate on the failures. Send interacting problems together in one message, and independent ones one at a time.
- **Don't grade your own homework.** The context that wrote a change is the worst one to review it. Run the `review` skill, which uses the independent `reviewer` subagent, before opening a PR.
- **Long sessions:** keep key facts (numbers, IDs, paths, decisions) in a scratchpad. Compact the context when it fills with exploration output. To continue later, the `handoff` skill writes a summary for a fresh session; that is more reliable than resuming with stale tool results. When resuming, say which files changed.
- **Hooks enforce; this file guides.** Anything that must always hold is a hook or a CI gate. If a hook blocks you, that is the rule working.
