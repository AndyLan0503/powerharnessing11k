# models/

Model files (trained models, fitted parameters, solver configurations or warm starts, anything a run produces and later runs depend on) stay **out of git**. `artifacts.lock` records their content hashes. See `docs/ARTIFACTS.md`.

Name files so a version is visible without opening them, e.g. `<name>-<YYYYMMDD>-<shorthash>.<ext>`, and never overwrite a recorded file: write a new one and snapshot it.

<!-- TODO(team): list each model: what it is, the command and data versions that produce it, and where it is used. -->
