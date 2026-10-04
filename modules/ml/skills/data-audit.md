---
name: data-audit
description: Audit a dataset in {{PROJECT_NAME}} before using it: schema, quality, leakage, splits, and documentation. Use when adding a new dataset, changing preprocessing, or when results look too good.
---

# Data audit

Work read-only on `data/raw/`. Write any derived outputs to `data/processed/` from a script.

1. **Provenance.** Where did it come from, under what license, and which version or date? Record it in `docs/DATA.md`.
2. **Schema.** Columns and types, units, allowed ranges, primary key. Flag type mismatches and unexpected categories.
3. **Quality.** Missing values per column, duplicates (exact and near), outliers, impossible values, label noise.
4. **Leakage.** Features derived from the target or from the future; the same entity (user, patient, document) appearing in both train and test; time-ordering violations; target encoding fitted on all data.
5. **Splits.** How train/validation/test are made (random, grouped, temporal) and whether that matches deployment. Check class balance per split.
6. **Sensitive data.** Personal or protected attributes present? Never print raw rows that contain them; summarise instead.
7. **Report.** Write findings as a dataset card in `docs/DATA.md` (template there), and list concrete fixes. Don't apply fixes to raw data.
