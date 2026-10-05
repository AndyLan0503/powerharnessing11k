# shellcheck shell=bash
MODULE_DESC="Makefile as the single command interface, test tiers (docs/TESTING.md); in empty Python/uv repos a working pyproject + src/ + tests/ skeleton"

module_apply() {
  if [ -n "$HV_USE_MAKE" ]; then emit file Makefile.tmpl Makefile; fi
  emit file TESTING.md docs/TESTING.md
  if [ -n "$HV_SCAFFOLD_PYTHON" ]; then
    emit file python/pyproject.toml pyproject.toml
    emit file python/python-version .python-version
    emit file python/init.py "src/$HV_PY_PACKAGE/__init__.py"
    emit file python/py.typed "src/$HV_PY_PACKAGE/py.typed"
    emit file python/conftest.py tests/conftest.py
    emit file python/test_smoke.py tests/unit/test_smoke.py
    emit append python/gitignore.tmpl .gitignore
  fi
  if [ -n "$HV_USE_MAKE" ]; then
    settings_allow_cmd 'make lint' 'make typecheck' 'make test' 'make check'
  fi
}
