---
paths: [".github/**"]
---

# Editing CI and GitHub configuration

- These files control what protects the repo. Changes need a human code-owner review{{#if GUARD_STRICT}}, and agents are blocked from editing them in strict mode{{/if}}.
- Give each workflow the least `permissions:` it needs; default to `contents: read`.
- Never echo secrets, and never pass untrusted input (PR titles, branch names, comment bodies) directly into `run:` scripts. Pass it through `env:`.
- Avoid `pull_request_target` with a checkout of PR code.
- Never weaken a required check (removing steps, adding `continue-on-error`, skipping tests) to get a PR green.
