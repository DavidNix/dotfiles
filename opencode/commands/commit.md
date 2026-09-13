---
description: Make an atomic git commit of the current changes
agent: build
---

Create one atomic git commit from the current working tree.

1. Inspect the repository: run `git status`, `git diff`, and `git diff --staged`, and review recent history with `git log --oneline -10` to match the repository's commit style.
2. Determine the single logical unit of work the current changes represent.
3. Stage only the files that belong to that unit. Do not stage unrelated, partially-complete, or unrelated dirty changes. If the changes span multiple unrelated units, stop and ask which unit to commit.
4. Refuse to commit if you cannot confidently describe the change in a single coherent message. Never commit secrets, credentials, or private keys.
5. Write a concise commit message in the repository's existing style, with a subject line of 50 characters or fewer. Add a body only when it adds meaningful context.
6. Commit with `git commit` and never use `--amend`, `--force`, `-i`, skip hooks, or create empty commits.
7. Report the resulting commit SHA and a one-line summary.

$ARGUMENTS