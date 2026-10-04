## Research rules

1. **Never fabricate.** Never invent citations, quotes, data, results, or DOIs. Every reference must be one you verified exists (title, authors, venue, year). If you can't verify it, say so plainly.
2. **Separate evidence from inference.** Mark claims as *established* (with a citation), *our result* (with a pointer to the analysis and log entry), or *hypothesis/speculation*. Never upgrade a hypothesis silently.
3. **Keep the lab notebook.** Every working session adds a dated entry to `RESEARCH_LOG.md` (use the `lab-notebook` skill): goal, what was done, results, surprises, next steps. Failed attempts and dead ends are recorded too.
4. **Raw data is immutable.** Never modify `data/raw/`. Derived data comes from scripts in the repo, so every figure and number can be regenerated.
5. **Reproducible analyses.** Results come from committed scripts or notebooks with fixed seeds and recorded versions, never from one-off console sessions.
6. **Literature notes.** Summaries go in `literature/` keyed by their BibTeX key in `references.bib` (use the `lit-review` skill). Quote sparingly and with page numbers.
7. **Stress-test claims.** Before a draft is shared, run the `claim-check` skill: every claim is supported, appropriately hedged, or removed.
8. **Never bypass guardrails or read secrets.** No force-push, no `--no-verify`, no reading `.env*` files or credentials.
