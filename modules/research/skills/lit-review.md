---
name: lit-review
description: Find, verify, and summarise papers or sources into literature/ notes with BibTeX entries in references.bib. Use when surveying prior work, looking for a citation, or reading a paper.
argument-hint: "[topic, question, or paper]"
---

# Literature review

1. **Search.** Use precise queries; prefer primary sources (papers, official docs, datasets) over blogs and summaries.
2. **Verify before citing.** Confirm the work exists and get its exact title, authors, venue, year, and DOI or URL from an authoritative page. **Never construct a citation from memory.** If you can't verify one, say "unverified" and don't add it.
3. **BibTeX.** Add the entry to `references.bib` with a key like `lastnameYEARword` (e.g. `vaswani2017attention`). Don't create duplicate keys.
4. **Note.** Create `literature/<key>.md`:
   - Publication date (and data-collection period, if relevant)
   - Claim(s) and evidence: what they show and how (data, method, sample size), each claim with its location (page or section) so the claim→source link survives later summarising
   - Limitations and threats to validity
   - Relevance to our questions
   - Exact quotes only when needed, with page or section numbers
5. **Synthesise.** When several notes exist, update `literature/README.md` with how the works relate. Keep well-established and contested findings in separate sections. When sources conflict, keep both values with their sources, methods, and dates (check whether timing explains the difference). Annotate gaps where sources were unavailable.

Distinguish clearly between what a paper *claims* and what it *demonstrates*.
