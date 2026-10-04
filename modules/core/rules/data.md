---
paths: ["data/**"]
---

# Working with data files

- `data/raw/` is immutable; agents are blocked from editing it. Derived data goes to `data/interim/` or `data/processed/`, produced by a committed script you can name.
- Read data with tools that summarise (schema, counts, `head`) rather than printing whole files into the conversation.
- Never print rows containing personal or sensitive data; aggregate or redact instead.
- Record dataset provenance and version{{#if MOD_ML}} in `docs/DATA.md`{{/if}}{{#if MOD_RESEARCH}} in the `RESEARCH_LOG.md` entry that uses it{{/if}}.
