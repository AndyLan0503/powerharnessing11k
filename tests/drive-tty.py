#!/usr/bin/env python3
"""Drive an interactive command through a pseudo-terminal, for wizard tests.

Usage: drive-tty.py OUT_FILE CMD [ARGS...] < keys
Each line of stdin is one input: "key:X" sends a single key, "line:TEXT"
sends TEXT plus Enter. All terminal output is written to OUT_FILE.
"""
import os
import pty
import select
import sys
import time


def main():
    out_path, cmd = sys.argv[1], sys.argv[2:]
    inputs = [l.rstrip("\n") for l in sys.stdin if l.strip()]
    pid, fd = pty.fork()
    if pid == 0:
        os.execvp(cmd[0], cmd)
    out = bytearray()

    def drain(wait):
        end = time.time() + wait
        while time.time() < end:
            ready, _, _ = select.select([fd], [], [], 0.05)
            if ready:
                try:
                    chunk = os.read(fd, 65536)
                except OSError:
                    return False
                if not chunk:
                    return False
                out.extend(chunk)
        return True

    for item in inputs:
        drain(0.4)
        kind, _, value = item.partition(":")
        os.write(fd, (value if kind == "key" else value + "\r").encode())
    while drain(1.0) and len(out) < 2_000_000:
        _, status = os.waitpid(pid, os.WNOHANG)
        if _:
            break
    with open(out_path, "w") as f:
        f.write(out.decode(errors="replace").replace("\r", ""))


if __name__ == "__main__":
    main()
