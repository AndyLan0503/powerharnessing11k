---
name: experiment
description: Plan, run, and log an ML or data-science experiment in {{PROJECT_NAME}} reproducibly. Use whenever training a model, comparing approaches, tuning hyperparameters, or reporting a metric.
argument-hint: "[hypothesis]"
---

# Running an experiment

## Before running
1. **Hypothesis.** One sentence: "Changing X will improve metric M on dataset D because ...".
2. **Baseline.** Identify the current best result in `docs/EXPERIMENTS.md`, or run a simple baseline first. No baseline, no conclusion.
3. **Config.** Put every knob (data version, features, model, hyperparameters, seed) in a config file or CLI arguments. Never in an edited notebook cell.
4. **Cost check.** Estimate runtime, GPU, and storage. Ask before anything long or costly.

## Running
- Fix seeds (Python, NumPy, framework). Record library versions and the git SHA.
- Fit preprocessing on the training split only. Never touch the test set until the final evaluation.
- Prefer several seeds, or a confidence interval, over one lucky run.
{{#if EVAL_CMD}}
- Evaluate with `{{EVAL_CMD}}` so numbers are comparable across experiments.
{{/if}}

## After running
Append an entry to `docs/EXPERIMENTS.md`:

```markdown
## YYYY-MM-DD: <short name>
- Hypothesis:
- Config: <path or args>, seed(s), data version, git SHA
- Result: <metric ± spread> vs baseline <metric>
- Conclusion: supported / not supported / inconclusive, and why
- Next:
```

Report the result to the user exactly as measured. Negative and inconclusive results are logged too.
