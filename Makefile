SHELL_SOURCES := bin/harness lib/*.sh tests/run.sh setup.sh

.PHONY: lint test check

lint:
	shellcheck -x $(SHELL_SOURCES)

test:
	tests/run.sh

check: lint test
