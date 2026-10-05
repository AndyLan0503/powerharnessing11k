# Review checklist

<!-- Humans and the Claude review workflow both use this file; adapt it to the repo. -->

## Always check

1. **Correctness.** Name concrete inputs that break it. Edge cases: empty, null, very large, concurrent, unicode.
2. **Tests.** Behavior changes come with tests. Tests are not deleted, skipped, or weakened to pass.
3. **Scope.** The diff matches the PR description and linked issue. No drive-by changes.
4. **Security.** No secrets, no injection (SQL, shell, template), and authz is checked on new endpoints. Untrusted input is validated.
5. **Dependencies.** New ones are justified, maintained, and appropriately licensed.
6. **Operability.** Errors are handled and logged usefully; there are no silent catches.
7. **Agent PRs** (`agent-authored`): check the agent-guard summary, and verify any claim like "tests pass" against CI.

## Severity

- 🔴 **Blocking:** bugs, security issues, missing tests for changed behavior.
- 🟡 **Nit:** style, naming, small clarity wins. Never blocks a merge.
