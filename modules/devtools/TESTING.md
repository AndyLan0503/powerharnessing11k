# Testing

Tests are the contract for humans and agents alike. They are organised in **tiers** by cost, so the cheap ones run on every change and the expensive ones run on a schedule.

| Tier | What it checks | Where it lives | When it runs |
|---|---|---|---|
| **Unit** | One function or class, in isolation; fast and deterministic | `tests/unit/` | Every change (`make test`), every PR |
| **Integration** | Real interactions across modules, files, processes, or services | `tests/integration/` | Every PR |
| **Property-based** | Invariants that must hold for *any* valid input (generated inputs) | `tests/property/` | Every PR, with a bounded number of examples |
| **Regression (golden)** | Outputs on fixed inputs match recorded results, within stated tolerances | `tests/regression/` | Full tier (`make test-all`): nightly, and before releases |
| **Performance** | Runtime, memory, and quality budgets don't regress | `tests/benchmarks/` | Full tier, tracked over time |
{{#if MOD_ARTIFACTS}}
| **On real artifacts** | End-to-end on the actual local data and models | marked to need verified artifacts | Locally; skipped when `scripts/artifacts.sh verify` fails (e.g. in CI) |
{{/if}}

{{#if FULL_TEST_CMD}}
- `make test`: the fast tier, `{{TEST_CMD}}`
- `make test-all`: everything, `{{FULL_TEST_CMD}}`
{{/if}}
{{#unless FULL_TEST_CMD}}
- `make test` runs the suite. TODO(team): when slow tiers appear, add a separate fast/full split and a nightly job.
{{/if}}

## Rules

1. **Every behavior change comes with a test** in the lowest tier that can catch it.
2. **Deterministic or it doesn't count.** Fix seeds, freeze time, avoid the network, and give anything iterative or randomised a fixed budget (iterations, time limit, tolerance). A flaky test is a bug.
3. **Compare numbers with explicit tolerances**, and write down why each tolerance is what it is.
4. **Golden results are reviewed, never regenerated to make a failure go away.** When a golden output changes, the PR says why it changed and shows the old vs new values.
{{#if MOD_ARTIFACTS}}
5. **Pin inputs.** Regression and real-data tests name the artifacts they use; their hashes are in `artifacts.lock`. A result is only comparable to another result made from the same hashes.
{{/if}}
{{#unless MOD_ARTIFACTS}}
5. **Pin inputs.** Regression tests use small, committed fixtures; record where any larger inputs come from.
{{/if}}
6. **Never delete, skip, or loosen a test to get green.** If a test is wrong, fix it in a separate, clearly labelled change.

## Project-specific testing

<!-- TODO(team): fill in, then delete this comment.
- Which invariants matter most in this domain, and which tier checks each one.
- Reference cases with known answers (where they come from, and how they were verified).
- Budgets: acceptable runtime and quality thresholds, and how they are measured.
- Any checks beyond tests (e.g. validating outputs against independent checkers). -->
