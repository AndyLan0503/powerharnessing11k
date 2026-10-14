SHELL_SOURCES := bin/harness lib/*.sh agents/*/adapter.sh tests/run.sh setup.sh docs/demo/fingerprint.sh

.PHONY: lint test check demo

lint:
	shellcheck -x $(SHELL_SOURCES)

test:
	tests/run.sh

check: lint test

# Re-record the README demo after a wizard change (needs vhs).
demo:
	vhs docs/demo/wizard.tape
	docs/demo/fingerprint.sh >docs/demo/wizard.fingerprint
