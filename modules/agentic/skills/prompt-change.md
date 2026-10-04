---
name: prompt-change
description: Change a prompt, tool description, model, or agent loop in {{PROJECT_NAME}} safely, with evals before and after. Use for any change that alters model behavior.
---

# Changing model behavior

1. **State the goal.** Which failure are you fixing, or which behavior are you adding? Find or write eval cases in `evals/cases/` that demonstrate it. A bug fix starts with a failing case.
2. **Baseline.** Run the evals on the current version{{#if EVAL_CMD}} (`{{EVAL_CMD}}`){{/if}} and save the numbers.
3. **Change one thing.** Edit the prompt file under `prompts/`, or the tool or model config. Don't mix prompt rewrites with code refactors.
4. **Re-run the evals.** Compare pass rate, the specific target cases, cost (tokens), and latency. Look at *regressions* case by case, not just the aggregate.
5. **Check the edges.** Try adversarial inputs: prompt injection in tool results or user content, empty and huge inputs, other languages, refusal-worthy requests.
6. **Report** in the PR: before → after table, the regressions and why they're acceptable (or fixed), and the cost/latency delta.

Never claim an improvement from a single example. If evals are noisy, run them more than once.
