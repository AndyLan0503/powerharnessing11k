SHELL_SOURCES := bin/harness lib/*.sh agents/*/adapter.sh tests/run.sh setup.sh

.PHONY: lint test check demo demo-check

lint:
	shellcheck -x $(SHELL_SOURCES)

test:
	tests/run.sh

check: lint test

# Replay the README demo's keystrokes against the wizard (not part of `make test`).
demo-check:
	DEMO_TESTS=1 tests/run.sh demo_test_

# Re-record the README demo (needs vhs). Only when the wizard visibly changed.
demo: demo-check
	vhs docs/demo/wizard.tape
