---
name: task-intake
description: How to start a new task or issue in harness-workflow: clarify scope, branch, plan, and test-first. Use at the beginning of any feature, fix, or refactor.
argument-hint: "[issue number or task description]"
---

# Task intake

1. **Read the issue fully**, including comments. Write down the acceptance criteria in your own words. If there are none, propose them and ask before coding.
2. **Find the blast radius.** Locate the code involved and its tests. Note anything the change could break.
3. **Branch** from an up-to-date `main`: `<type>/<short-slug>` (e.g. `fix/login-redirect`).
4. **Plan briefly.** List the files you expect to touch. If it is more than a handful, or touches public APIs, share the plan first.
5. **Test first** where practical: write or extend a failing test that captures the acceptance criteria.
6. **Implement** the smallest change that passes. No drive-by refactors; note them in the PR as follow-ups.
7. **Verify**: run lint and tests, and report the results honestly in the PR description.
8. **Open the PR** using the template. Link the issue, list what you verified, and call out anything you are unsure about.
