---
paths: ["data/**", "models/**", "artifacts.lock"]
---

# Data and model artifacts

- Files under `data/` and `models/` are not in git; `artifacts.lock` records their hashes (see `docs/ARTIFACTS.md`).
- Before using artifacts for a result, a test, or a benchmark, run `scripts/artifacts.sh verify`. If it fails, stop and report which files differ; don't silently proceed on different data.
- Never edit a recorded file in place. Write a new file (new name), then ask before running `scripts/artifacts.sh snapshot -m "<why>"`. Snapshots change what the repo pins.
- Never hand-edit `artifacts.lock`.
- When reporting any result, include the short hashes of the artifacts it used (`scripts/artifacts.sh hash <path>`).
- Inspect data with summaries (shape, schema, counts, `head`), never by printing whole files into the conversation.
