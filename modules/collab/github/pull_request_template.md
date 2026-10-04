## What and why

<!-- One or two sentences. Link the issue: "Closes #123". -->

## How it was verified

{{#if LINT_CMD}}
- [ ] `{{LINT_CMD}}`
{{/if}}
{{#if TEST_CMD}}
- [ ] `{{TEST_CMD}}`
{{/if}}
- [ ] New or changed behavior is covered by tests
- [ ] Manually checked (describe):

## Agent involvement

- [ ] No agent involved
- [ ] Agent-assisted (a human wrote or substantially rewrote the change)
- [ ] Agent-authored (an agent wrote the change; a human reviewed it)

<!-- Agent-authored PRs: keep the Co-Authored-By trailer in commits. CI labels
     the PR and runs extra agent-guard checks. -->

## Risk

<!-- What could break? New dependencies? Migrations? Anything reviewers should look at closely? -->
