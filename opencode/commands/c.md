---
description: Make an atomic git commit of the current changes
---

Make an atomic commit of the current changes.

First, run `git log --oneline -20` and inspect the existing commit style, then match it exactly. Note:
- Prefixes (e.g. `feat:`, `fix:`, `docs:`, `chore:`) — use them if the repo uses them, with matching case and punctuation
- Language: capitalized vs lowercase, imperative vs past tense

Rules:
- Stage and commit only related changes; split unrelated changes into separate atomic commits
- Write the message to match the repo's established style
- Never add Claude/AI attribution or `Co-Authored-By` footers

$ARGUMENTS
