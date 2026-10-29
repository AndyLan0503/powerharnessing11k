#!/usr/bin/env python3
"""Drive an interactive command through a pseudo-terminal, for wizard tests.

Usage: drive-tty.py OUT_FILE CMD [ARGS...] < keys
Each line of stdin is one input: "key:X" sends a single key, "line:TEXT"
sends TEXT plus Enter. All terminal output is written to OUT_FILE.

Each input is sent once the command shows its next prompt: a choice
("... ]: ", maybe followed by the marked answer) or a line ("[default] ").
A command that shows no prompt within a few seconds gets the input anyway.
"""
import os
import pty
import re
import select
import signal
import sys
import time

PROMPT = re.compile(rb"(\]: [^\n]*|\] )\Z")
ANSI = re.compile(rb"\x1b\[[0-9;?]*[A-Za-z]")
SETTLE = 0.02  # a prompt is complete once output pauses this long
PATIENCE = 5.0  # longest wait for a prompt before sending anyway


def main():
    out_path, cmd = sys.argv[1], sys.argv[2:]
    inputs = [l.rstrip("\n") for l in sys.stdin if l.strip()]
    pid, fd = pty.fork()
    if pid == 0:
        os.execvp(cmd[0], cmd)
    out = bytearray()

    def read(timeout):
        """Read what is available within timeout. False once the command is gone."""
        ready, _, _ = select.select([fd], [], [], timeout)
        if not ready:
            return True
        try:
            chunk = os.read(fd, 65536)
        except OSError:
            return False
        if not chunk:
            return False
        out.extend(chunk)
        return True

    def wait_for_prompt(since):
        """Wait for new output that ends in a prompt and then pauses."""
        deadline = time.time() + PATIENCE
        while time.time() < deadline:
            before = len(out)
            if not read(SETTLE):
                return
            settled = len(out) == before
            tail = ANSI.sub(b"", bytes(out[since:])).rstrip(b"\r")
            if settled and len(out) > since and PROMPT.search(tail):
                return

    sent_at = 0
    for item in inputs:
        wait_for_prompt(sent_at)
        sent_at = len(out)
        kind, _, value = item.partition(":")
        os.write(fd, (value if kind == "key" else value + "\r").encode())
    # Wait for the command to finish. If it is still asking for input after
    # the script ran out (a wrong key sequence), stop it instead of hanging.
    deadline = time.time() + 20
    while read(0.1) and len(out) < 2_000_000:
        done, _ = os.waitpid(pid, os.WNOHANG)
        if done:
            break
        if time.time() > deadline:
            os.kill(pid, signal.SIGKILL)
            out.extend(b"\n[drive-tty: timed out waiting for the command to exit]\n")
            break
    with open(out_path, "w") as f:
        f.write(out.decode(errors="replace").replace("\r", ""))


if __name__ == "__main__":
    main()
