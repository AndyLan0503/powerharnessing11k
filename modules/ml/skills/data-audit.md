---
name: data-audit
description: Audit a dataset in {{PROJECT_NAME}} before using it: schema, quality, leakage, splits, and documentation. Use when adding a new dataset, changing preprocessing, or when results look too good.
argument-hint: "[dataset path]"
context: fork
allowed-tools: Read, Grep, Glob, Bash
---

# Data audit

Read-only: inspect with summaries (schema, counts, distributions), never by dumping whole files.

1. **Provenance.** Where did it come from, under what license, and which version or date? Record it in `docs/DATA.md`.
2. **Schema.** Columns and types, units, allowed ranges, primary key. Flag type mismatches and unexpected categories.
3. **Quality.** Missing values per column, duplicates (exact and near), outliers, impossible values, label noise.
4. **Leakage.** Features derived from the target or from the future; the same entity (user, patient, document) appearing in both train and test; time-ordering violations; target encoding fitted on all data.
5. **Splits.** How train/validation/test are made (random, grouped, temporal) and whether that matches deployment. Check class balance per split.
6. **Sensitive data.** Personal or protected attributes present? Never print raw rows that contain them; summarise instead.
7. **Report.** This skill runs read-only in a forked context. Return the findings as a dataset card (template in `docs/DATA.md`) plus a list of concrete fixes, for the main session to save. Never modify raw data.
