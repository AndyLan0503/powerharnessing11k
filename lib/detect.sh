# shellcheck shell=bash
# Stack detection and per-stack command defaults. Every default can be
# overridden in the wizard or by editing .harness/config.

detect_stack() { # dir -> node|python|go|rust|generic
  local d=$1
  if [ -f "$d/package.json" ]; then
    echo node
  elif [ -f "$d/pyproject.toml" ] || [ -f "$d/requirements.txt" ] || [ -f "$d/setup.py" ]; then
    echo python
  elif [ -f "$d/go.mod" ]; then
    echo go
  elif [ -f "$d/Cargo.toml" ]; then
    echo rust
  else
    echo generic
  fi
}

detect_pkg_manager() { # dir stack
  local d=$1
  case $2 in
    node)
      if [ -f "$d/pnpm-lock.yaml" ]; then echo pnpm
      elif [ -f "$d/yarn.lock" ]; then echo yarn
      elif [ -f "$d/bun.lockb" ] || [ -f "$d/bun.lock" ]; then echo bun
      else echo npm; fi
      ;;
    python)
      if [ -f "$d/uv.lock" ]; then echo uv
      elif [ -f "$d/poetry.lock" ]; then echo poetry
      else echo pip; fi
      ;;
    go) echo go ;;
    rust) echo cargo ;;
    *) echo none ;;
  esac
}

detect_default_branch() { # dir
  local b
  b=$(git -C "$1" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null) && {
    echo "${b#origin/}"
    return
  }
  b=$(git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null) || b=''
  case $b in main | master | trunk | develop) echo "$b" ;; *) echo main ;; esac
}

# Sets HV_INSTALL_CMD HV_LINT_CMD HV_TYPECHECK_CMD HV_TEST_CMD HV_FORMAT_CMD
# from HV_STACK and HV_PKG_MANAGER. FORMAT_CMD uses {file} for the edited path.
stack_defaults() {
  local pm=$HV_PKG_MANAGER run
  HV_INSTALL_CMD='' HV_LINT_CMD='' HV_TYPECHECK_CMD='' HV_TEST_CMD='' HV_FORMAT_CMD=''
  case $HV_STACK in
    node)
      case $pm in
        pnpm) HV_INSTALL_CMD='pnpm install --frozen-lockfile'; run='pnpm run --if-present' ;;
        yarn) HV_INSTALL_CMD='yarn install --immutable'; run='yarn run' ;;
        bun) HV_INSTALL_CMD='bun install --frozen-lockfile'; run='bun run' ;;
        *) HV_INSTALL_CMD='npm ci'; run='npm run --if-present' ;;
      esac
      HV_LINT_CMD="$run lint"
      HV_TYPECHECK_CMD="$run typecheck"
      HV_TEST_CMD="$run test"
      HV_FORMAT_CMD='npx --no-install prettier --write {file}'
      ;;
    python)
      case $pm in
        uv)
          HV_INSTALL_CMD='uv sync'
          HV_LINT_CMD='uv run ruff check .'
          HV_TEST_CMD='uv run pytest'
          HV_FORMAT_CMD='uv run ruff format {file}'
          ;;
        poetry)
          HV_INSTALL_CMD='poetry install'
          HV_LINT_CMD='poetry run ruff check .'
          HV_TEST_CMD='poetry run pytest'
          HV_FORMAT_CMD='poetry run ruff format {file}'
          ;;
        *)
          HV_INSTALL_CMD='pip install -r requirements.txt'
          HV_LINT_CMD='ruff check .'
          HV_TEST_CMD='pytest'
          HV_FORMAT_CMD='ruff format {file}'
          ;;
      esac
      ;;
    go)
      HV_INSTALL_CMD='go mod download'
      HV_LINT_CMD='go vet ./...'
      HV_TEST_CMD='go test ./...'
      HV_FORMAT_CMD='gofmt -w {file}'
      ;;
    rust)
      HV_INSTALL_CMD='cargo fetch'
      HV_LINT_CMD='cargo clippy --all-targets -- -D warnings'
      HV_TEST_CMD='cargo test'
      HV_FORMAT_CMD='rustfmt {file}'
      ;;
  esac
  export HV_INSTALL_CMD HV_LINT_CMD HV_TYPECHECK_CMD HV_TEST_CMD HV_FORMAT_CMD
}
