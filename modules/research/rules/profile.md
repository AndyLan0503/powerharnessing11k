## Research rules

1. **Never fabricate.** Never invent citations, quotes, data, results, or DOIs. Every reference must be one you verified exists (title, authors, venue, year). If you can't verify it, say so plainly.
2. **Keep claims attached to sources.** Every finding carries its source (URL or BibTeX key, location, short excerpt) and its publication or collection date, from note-taking through synthesis. Never let a summary step drop the claim→source mapping.
3. **Separate evidence from inference.** Mark claims as *established* (cited), *our result* (pointing to the analysis and log entry), or *hypothesis*. In reports, put well-established and contested findings in separate sections.
4. **Report conflicts; don't resolve them silently.** When credible sources disagree, keep both values with their sources and methods, and check whether a date difference explains it. Annotate coverage gaps where sources were unavailable.
5. **Keep the lab notebook.** Every working session adds a dated entry to `RESEARCH_LOG.md` (use the `lab-notebook` skill), including failures and dead ends.
6. **Raw data is immutable; analyses are reproducible.** Never modify `data/raw/`. Results come from committed scripts or notebooks with fixed seeds and recorded versions.
7. **Stress-test claims before sharing.** Run the `claim-check` skill, and the `/review` command for an independent read of important drafts.
8. **Never bypass guardrails or read secrets.** No force-push, no `--no-verify`, no reading `.env*` files or credentials.
