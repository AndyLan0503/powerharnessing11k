---
paths: ["**/*.test.*", "**/*.spec.*", "**/*_test.*", "**/test_*.py", "**/tests/**", "**/__tests__/**", "**/spec/**"]
---

# Writing and changing tests

- Test behavior through public interfaces, not private helpers or implementation details.
- Cover the happy path, the edge cases named in the task, and at least one failure mode. Prefer one behavior per test, with a name that says what it guarantees.
- Tests are deterministic: no real network, no wall-clock sleeps, fixed seeds, and temp dirs instead of shared paths.
- Reuse existing fixtures and helpers before writing new ones; read neighbouring tests first and mirror their style. Don't add tests that duplicate scenarios already covered.
- Never delete, skip, or loosen an existing test to make a change pass. If a test is wrong, say why and fix it in a separate, clearly labelled change.
{{#if TEST_CMD}}
- Run `{{TEST_CMD}}` and report the actual result.
{{/if}}
