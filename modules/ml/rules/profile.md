## Data science and ML rules

1. **Raw data is immutable.** Never modify `data/raw/`. Every derived dataset is produced by a script in the repo, never by hand or by a notebook cell nobody can re-run.
2. **No data, models, or secrets in git.** Datasets, checkpoints, and model weights live in storage (or DVC/LFS), not in commits. Never print or log samples containing personal data.
3. **Reproducibility.** Fix random seeds, pin library versions, and record the exact config (hyperparameters, data version, git SHA) for every result you report.
4. **No leakage.** Never fit anything (scalers, encoders, feature selection, hyperparameters) on validation or test data. Split before you look. Say so if a split looks contaminated.
5. **Compare against a baseline, and look past the aggregate.** A metric without a baseline and a confidence interval (or several seeds) is not a result. Break results down by segment (class, source, cohort): a strong overall number can hide a failing slice. Report what you ran, not what you expect.
6. **Log every experiment** in `EXPERIMENTS.md` (use the `experiment` skill): hypothesis, config, result, conclusion. Negative results count.
7. **Notebooks are for exploration.** Move reusable logic into modules with tests. Clear outputs before committing.
8. **Calibrate before you automate.** Before trusting model confidence to skip human review, check calibration on a labelled validation set and keep sampling high-confidence predictions for errors.
9. **Ask before expensive runs.** Confirm before starting long training jobs, GPU work, or anything that downloads large datasets or costs money.
