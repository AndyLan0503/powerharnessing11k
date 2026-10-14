# The wizard demo shown in the README. Regenerate it with `make demo`
# (needs https://github.com/charmbracelet/vhs) after changing the wizard.
#
# It bootstraps an empty folder in a throwaway HOME, so it never touches
# your machine, and runs this checkout as ~/powerharnessing11k/setup.sh to
# match the README's install instructions.

Output docs/demo/wizard.gif

Require bash

Set Shell "bash"
Set FontSize 14
Set Width 1560
Set Height 940
Set Padding 24
Set Theme "Catppuccin Mocha"
Set TypingSpeed 60ms
Set CursorBlink false
Set Framerate 24

Hide
Type `export DEMO_REPO=$PWD DEMO_HOME=$(mktemp -d /tmp/you.XXXX)`
Enter
Type `ln -s "$DEMO_REPO" "$DEMO_HOME/powerharnessing11k" && mkdir -p "$DEMO_HOME/work/opt-engine"`
Enter
Type `export HOME=$DEMO_HOME PS1='\[\e[38;5;39m\]\w\[\e[0m\] $ ' && cd "$DEMO_HOME/work/opt-engine" && clear`
Enter
Sleep 500ms
Show

# An empty folder: the wizard offers to `git init` it first.
Type "~/powerharnessing11k/setup.sh"
Sleep 600ms
Enter
Sleep 1s
Type "y"
Sleep 400ms
Enter
Sleep 2s

# Each answer: a key marks it on screen, Enter confirms.
# [1/10] What is this repository for?  Software engineering
Sleep 1s
Type "1"
Sleep 1s
Enter
# [2/10] Language or toolchain?  Python
Sleep 1.5s
Type "2"
Sleep 1s
Enter
# [3/10] The detected commands are fine.
Sleep 2s
Type "1"
Sleep 800ms
Enter
# [4/10] Coding agents: add Codex CLI next to Claude Code.
Sleep 1.2s
Type "2"
Sleep 1s
Enter
# [5/10] How much harness?  Recommended
Sleep 1.5s
Type "2"
Sleep 1s
Enter
# [6/10] Version data and model files.
Sleep 1.2s
Type "1"
Sleep 800ms
Enter
# [7/10] Name a few project-specific stubs.
Sleep 1.2s
Type "2"
Sleep 800ms
Enter
Sleep 1.2s
Type "formulate run-solver"
Enter
Type "model-checker"
Enter
Type "solver=src/*/solver/**"
Enter
Sleep 400ms
Enter
Sleep 1.2s
# [8/10] Code owners
Type "@acme/opt"
Sleep 400ms
Enter
# [9/10] No telemetry export.
Sleep 1.2s
Type "1"
Sleep 800ms
Enter
# [10/10] Review every answer, then apply.
Sleep 3.5s
Type "y"
Sleep 1.2s
Enter
Sleep 7s

Hide
Type `cd / && rm -rf "$DEMO_HOME"`
Enter
