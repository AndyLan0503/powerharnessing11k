# Data and model artifacts

Large files (datasets, trained models, generated inputs and outputs) live **only on disk**, in `data/` and `models/`, and are git-ignored. What *is* committed is `artifacts.lock`: one line per file with its SHA-256, size, path, date, and a note. A commit therefore pins the exact artifacts it was built and tested with, without storing them.

## Everyday commands

```sh
scripts/artifacts.sh status                  # what changed, what is missing, what is unrecorded
scripts/artifacts.sh snapshot -m "why"       # record current files (default: data/ and models/)
scripts/artifacts.sh snapshot data/raw       # record just one area
scripts/artifacts.sh verify                  # exit 1 if any recorded file is missing or changed
scripts/artifacts.sh hash data/raw/x.csv     # short hash, for logs and result records
```

## Rules

1. **Snapshot in the same commit** as the code or config that depends on new data or a new model. The lock diff in the PR then shows exactly which artifacts changed.
2. **Verify before you trust a result.** Anything that reports numbers (tests on real data, benchmarks, experiments) should run `scripts/artifacts.sh verify` first, and record the hashes it used.
3. **Raw data is immutable.** A corrected dataset is a new file with a new hash, not an edit.
4. **Derived artifacts come from scripts.** Anything in `data/interim`, `data/processed`, or `models/` must be reproducible from committed code plus recorded inputs.

## Sharing artifacts between people

The lock records *what* the files are, not where to get them. Until there is shared storage, agree on one place to copy them from and write it below. A teammate copies the files in, then runs `scripts/artifacts.sh verify` to prove they have the same bytes.

<!-- TODO(team): where artifacts are shared today (a network drive, a bucket, a machine), and who can grant access. -->

## Moving to remote storage later

When cloud resources arrive, `artifacts.lock` is the migration list. Typical paths:
- **DVC** with an S3, GCS, or Azure remote: `dvc add` each recorded path, then `dvc push`. DVC's `.dvc` files then replace the lock.
- **Plain object storage**: upload by hash (`<bucket>/<sha256>`) and keep the lock as the index.

Provision that storage as code (for example in an `infra/` directory), so access and retention are reviewable.
