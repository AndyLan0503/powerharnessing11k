---
name: lab-notebook
description: Add a dated entry to RESEARCH_LOG.md recording goal, method, results, surprises, and next steps. Use at the end of every working session or after any analysis or experiment.
argument-hint: "[session title]"
---

# Lab notebook entry

Append to the top of `RESEARCH_LOG.md` (newest first):

```markdown
## YYYY-MM-DD: <short title>
**Question / goal:** what we were trying to find out.
**What we did:** methods, data (version), scripts and commit SHA, parameters.
**Results:** numbers and figures, with paths to the outputs that produced them.
**Interpretation:** what it suggests, labelled as *result* vs *hypothesis*.
**Surprises / problems:** anything unexpected, including failures and dead ends.
**Next:** concrete next steps.
```

Rules:
- Record what actually happened, including what didn't work. Never tidy up the history.
- Every number must be traceable to a committed script and recorded inputs.
- Don't edit past entries except to append a dated correction note.
