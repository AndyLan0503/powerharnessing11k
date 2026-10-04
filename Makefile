SHELL_SOURCES := bin/harness lib/*.sh tests/run.sh install.sh

.PHONY: lint test check

lint:
	shellcheck -x $(SHELL_SOURCES)

test:
	tests/run.sh

check: lint test
