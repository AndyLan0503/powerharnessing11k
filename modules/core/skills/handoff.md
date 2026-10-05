---
name: handoff
description: Save a structured handoff so a fresh session can continue this work reliably. Use when a session has run long or before stopping for the day.
argument-hint: "[short topic]"
---

# Handoff

Write a handoff file to `.agents/handoff/` named `<YYYY-MM-DD>-<slug of the topic you were given, or of the current task>.md`. These files are git-ignored and personal. Use exactly these sections:

1. **Goal**: what we are trying to achieve, and the acceptance criteria.
2. **Key facts**: exact values that must not be paraphrased (numbers, IDs, file paths, commands, error messages, dates).
3. **Decisions**: what was decided and why, including rejected alternatives.
4. **Current state**: files changed, what works, what is verified (and how), and what is not.
5. **Open questions and risks.**
6. **Next steps**: concrete, ordered, small.

Keep it under about 60 lines; link to files instead of pasting them. Then tell the user how to continue: start a new session and say "Read .agents/handoff/<file> and continue from Next steps", naming any files that change in the meantime.
