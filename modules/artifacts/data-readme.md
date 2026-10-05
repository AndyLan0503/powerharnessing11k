# data/

Data files stay **out of git** and live only on disk; `artifacts.lock` at the repo root records the exact content hash of each one. See `docs/ARTIFACTS.md`.

| Directory | Contents | Rules |
|---|---|---|
| `raw/` | Inputs exactly as received | Immutable: never edited in place. A new version is a new file, and gets a new snapshot. |
| `interim/` | Intermediate outputs | Produced only by committed scripts |
| `processed/` | Inputs to models, solvers, and tests | Produced only by committed scripts |

<!-- TODO(team): list each dataset: name, source, owner, how to obtain it, and the script that derives processed data from it. -->
