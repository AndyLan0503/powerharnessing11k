# shellcheck shell=bash
MODULE_DESC="Local data/model versioning: data/ and models/ out of git, committed artifacts.lock of content hashes, scripts/artifacts.sh"

module_apply() {
  emit exec artifacts.sh scripts/artifacts.sh
  emit file lock.tmpl artifacts.lock
  emit file data-readme.md data/README.md
  emit file models-readme.md models/README.md
  emit file ARTIFACTS.md docs/ARTIFACTS.md
  emit file rule.md .claude/rules/artifacts.md
  emit append gitignore.tmpl .gitignore
  settings_allow 'Bash(scripts/artifacts.sh verify:*)' 'Bash(scripts/artifacts.sh status:*)' \
    'Bash(scripts/artifacts.sh list:*)' 'Bash(scripts/artifacts.sh hash:*)'
}
