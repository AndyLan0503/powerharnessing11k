---
name: claim-check
description: Audit a draft (paper, report, slides, README) for unsupported, overstated, or mis-cited claims. Use before sharing or submitting anything that makes claims.
argument-hint: "[draft path]"
context: fork
allowed-tools: Read, Grep, Glob
---

# Claim check

For every factual or evaluative claim in the draft:

1. **Classify** it as *cited* (prior work), *ours* (our result), or *assumption/speculation*.
2. **Cited claims:** the reference exists in `literature/references.bib`, and the cited work actually supports this exact claim (check the note in `literature/`). Flag citations that support only a weaker version.
3. **Our results:** the number matches the source output, and is traceable to a `docs/RESEARCH_LOG.md` entry and a committed script. Check that uncertainty is reported and that sample sizes and conditions are stated.
4. **Wording:** flag overclaiming ("proves", "always", "state of the art") and causal language without causal evidence. Suggest calibrated wording.
5. **Missing:** limitations, alternative explanations, and relevant contrary work.

Output a table: claim (quoted, with location), status (OK / weak / unsupported / mis-cited), evidence, suggested fix. Don't silently rewrite the draft.
