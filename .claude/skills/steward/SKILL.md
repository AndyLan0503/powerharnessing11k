---
name: steward
description: How to drive a pull request in powerharnessing11k to a green, mergeable state. Use when CI fails, a reviewer comments, or a PR has a merge conflict.
argument-hint: "[PR number]"
---

# Steward: getting a PR to green

Work the PR in this order, re-checking the whole PR (CI on the latest commit, open threads, mergeability) after every push.

1. **Merge conflict.** Merge `main` into the branch (never rebase or force-push a shared branch). Regenerate lockfiles with the package manager (`none`), never by hand.
2. **CI red.** Reproduce the failure locally first. Find the root cause; "flaky" is not a root cause. Fix code, not tests: never skip, delete, or loosen a test to get green. If the failure is also red on `main`, say so on the PR instead of widening the change.
3. **Review comments.** Small, local asks (renames, a missing test, a nit): do them. Large asks (redesigns, API changes): reply with a proposal and wait for the author. Resolve threads you addressed and reply on the ones you didn't, saying why.

Before every push:
- `make lint`
- `make test`
- Re-read your own diff adversarially: what would make CI or a reviewer reject this?

One validated push beats three speculative ones. Never push an empty commit to re-trigger CI.
