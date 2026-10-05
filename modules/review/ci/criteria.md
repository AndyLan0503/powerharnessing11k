# AI review criteria

The PR gate's AI reviewer follows this file exactly. The team owns it: tune it in PRs. The reviewer also reads `AGENTS.md` for project context.

## Report these categories

| Category | Report when | Status |
|---|---|---|
| `correctness` | The code does something other than what it evidently intends, for a concrete input you can name | on |
| `security` | Injection (SQL, shell, template), missing authorization, secrets in code or logs, unsafe deserialization, untrusted input reaching a sink | on |
| `tests` | Changed behavior has no test, or a test was deleted, skipped, or weakened | on |
| `error-handling` | Errors are swallowed, misreported, or turn a partial result into a "success" | on |
| `concurrency` | Races, deadlocks, or shared mutable state without synchronization | on |
| `api-contract` | A public interface changed incompatibly without a version or migration path | on |
{{#if MOD_ML}}
| `data` | Train/test leakage, fitting on evaluation data, missing seeds or configs for a reported result | on |
{{/if}}
{{#if MOD_AGENTIC}}
| `prompt-injection` | Tool or retrieved content reaches the model as instructions rather than delimited data | on |
| `eval-coverage` | A prompt, tool, or model change without eval results or a regression case | on |
{{/if}}
| `performance` | An evident algorithmic or N+1 problem on a hot path (not micro-optimizations) | on |
| `docs-accuracy` | A comment or doc claims behavior the code contradicts | off |

Set a category's status to `off` to stop reporting it, for example while its false-positive rate is high (see the weekly digest's dismissal stats). Turn it back on once the criteria are sharper.

## Never report

- Style, formatting, naming, or import order (linters own these).
- Patterns that match the surrounding code's established conventions.
- Speculative issues without a concrete failure ("might be slow", "consider refactoring").
- Anything already in the list of prior findings you are given, unless it is still present; then mark it `still_present`.

## Severity

- **blocking**: will cause incorrect behavior, a security exposure, or data loss in a realistic scenario; or a behavior change without tests. Example: `if user.role = "admin":` (assignment, not a comparison); an SQL string built with f-strings from request input.
- **nit**: a real but minor problem worth fixing that is safe to merge as is. Example: an error message that names the wrong parameter.
- **pre-existing**: a real problem in code the diff touches that the diff did not introduce. Never blocking.

## Examples

Report (blocking, `security`):
> `api/users.py:42`: the query is built with an f-string from `request.args["id"]`, so SQL injection is possible. Fix: use a parameterized query. detected_pattern: `sql-string-concat`.

Don't report:
> A `try/except` that logs and re-raises: it does not swallow the error, and it matches the module's pattern.

Report (nit, `error-handling`):
> `cli/main.go:88`: the error wraps with "open config" but the failing call parses it. Fix: "parse config". detected_pattern: `misleading-error-context`.
