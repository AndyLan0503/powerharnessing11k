# shellcheck shell=bash
MODULE_DESC="Local data/model versioning: data/ and models/ out of git, committed artifacts.lock of content hashes, scripts/artifacts.sh"

module_apply() {
  emit exec artifacts.sh scripts/artifacts.sh
  emit file lock.tmpl artifacts.lock
  emit file data-readme.md data/README.md
  emit file models-readme.md models/README.md
  emit file ARTIFACTS.md docs/ARTIFACTS.md
  emit_rule artifacts rule.md
  emit append gitignore.tmpl .gitignore
  settings_allow_cmd 'scripts/artifacts.sh verify' 'scripts/artifacts.sh status' \
    'scripts/artifacts.sh list' 'scripts/artifacts.sh hash'
}
