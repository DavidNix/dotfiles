---
name: git-land
description: Rebase a feature branch onto the repo's main or master, resolve conflicts, then squash merge it into a local main/master commit. Use when the user wants to land or merge their current branch into main/master locally — not for a plain rebase, standalone conflict fixing, or any merge that keeps the feature branch.
---

# Land a branch

Get the current branch rebased and squash merged into the default branch with one clean commit. Move step by step.

## Preflight

Run these checks before touching anything:

```bash
git fetch --prune
git status --porcelain          # must be empty; abort and report if dirty
git branch --show-current       # the feature branch
```

Detect the default branch (the base). Try in order and use the first hit:

```bash
git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null
git rev-parse --verify --quiet origin/main && echo main
git rev-parse --verify --quiet origin/master && echo master
git rev-parse --verify --quiet main && echo main
git rev-parse --verify --quiet master && echo master
```

Refuse to continue if:
- The worktree is dirty (ask the user to stash or commit first).
- The current branch IS the base branch.
- No base branch can be found.

## Rebase onto the base

```bash
git rebase <base>
```

On conflict:

1. Read the conflicted files and both sides of each hunk (`git diff`, the file, and `git log <base>..<HEAD>` for intent).
2. Resolve conservatively: keep the base side for changes unrelated to this branch's purpose; keep the feature side for its own changes; combine when both edited the same region intentionally.
3. When a conflict is ambiguous, non-trivial, or touches logic you cannot verify, stop and ask the user. Never pick a side at random and never delete a conflicted file to "resolve" it.
4. Stage resolutions and `git rebase --continue`. Because a conflict means code was merged by hand, verify it compiles and tests pass if the repo has them.
5. If rebase goes wrong, `git rebase --abort` restores the starting state — report and ask rather than improvising.

If the rebase rewrote history on a previously pushed feature branch, leave the remote untouched — do not force push. Report the divergence and let the user update the remote themselves.

## Squash merge

```bash
git checkout <base>
git merge --ff-only <base>@{upstream} 2>/dev/null || git pull --ff-only   # ensure base is current
git merge --squash <feature-branch>
git diff --cached --stat               # sanity check: the expected files, nothing surprising
```

Then commit. Build the message from the feature branch's own history, not a generic summary:

```bash
git log <base>..<feature-branch> --oneline
```

- Subject: one concise line (50 chars or fewer when possible) describing why the change matters. Use the imperative mood ("Add retry logic to queue worker").
- Body: 2–4 short bullets of key context only when the change is not self-evident. Skip the body for small changes.
- Match the repo's existing commit style (`git log --oneline -15`) — conventional-commit prefixes, ticket numbers, or plain, whatever the repo already uses.
- Never add AI or LLM credits: no `Co-authored-by`, "Generated with", or bot trailers, even if repo templates suggest them.
- Commit with a heredoc so formatting is preserved:

```bash
git commit -m "$(cat <<'EOF'
Subject line

Optional body.
EOF
)"
```

## Cleanup

Do not push. Leaving the merge unpushed is intentional; the user pushes when ready.

- Verify the result with `git log --oneline -3`. Run no tests: a clean rebase changed nothing, and a conflicted rebase was already verified in the rebase step.
- Ask before deleting the feature branch. It requires `git branch -D` (not `-d`) because squash commits do not count as merged. Do not touch any remote branches.
- Leave the user checked out on the base branch.
