---
paths: ["evals/**"]
---

# Editing evals

- Every fixed bug gets a regression case. Every new tool gets cases where it *should* and *should not* be called.
- Cover segments deliberately: main tasks, edge inputs, adversarial and prompt-injection inputs, and cases that should refuse, escalate, or ask. Report results per segment; an aggregate pass rate can hide a failing slice.
- Prefer programmatic checks. When an LLM judge is necessary, version its prompt in `prompts/` and spot-check its verdicts against human labels.
- Never edit expected outputs just to make a run pass. If an expectation is wrong, explain why in the PR.
