---
paths: ["prompts/**"]
---

# Editing prompts and tool descriptions

- A prompt change is a behavior change: run the evals before and after, and report the delta (use the `prompt-change` skill).
- Keep stable instructions first and variable content last, so prompt caching keeps working.
- Prefer explicit criteria and 2–4 few-shot examples of *ambiguous* cases over adjectives like "careful" or "thorough".
- Tool descriptions say what the tool does, its input format, one example, edge cases, and when to use it instead of similar tools.
- Check for keyword-sensitive wording that could pull the model toward the wrong tool.
