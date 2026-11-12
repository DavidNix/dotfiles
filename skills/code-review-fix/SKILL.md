---
name: code-review-fix
description: Review code with the code-review skill, plus the security-review skill when the first argument is `security`. Fix and commit non-Critical findings without asking, then ask the user about Critical findings at the end. Use only when the user explicitly asks for code-review-fix.
argument-hint: "[security] [files, paths, or branch]"
---

# code-review-fix

If the first word of `$ARGUMENTS` is `security`, remove it and turn on the security review. The remaining arguments are the review scope.

## Review

1. Record the HEAD SHA and the dirty paths from `git status --porcelain`.
2. Invoke the `code-review` skill with the scope. If the security review is on, invoke `security-review` with the same scope. Edit nothing until both are done.
3. Merge findings with the same root cause. Confirm each finding in the code before you act on it.

## Fix

Do not stop for the user until the end.

- **Critical (`C*`, `SEC-C*`) or a fix that needs a major re-architecture or refactor:** do not fix. Save it for the end.
- **High, Medium, and Low:** fix it with the recommended solution.
- **Invalid:** skip it and note why.
- **Questions:** answer from the code, or save them for the end.

Commit each fix atomically: one root cause, with its tests, after its focused checks pass. Stage paths by name and follow the repo's commit style. Never amend, skip hooks, force, or push. If a file had uncommitted changes before the run, leave its fix uncommitted.

After all fixes, run focused checks over all the code you changed. Fix and commit any failure that you caused.

## Report

List these items: Critical and refactor findings with their possible solutions and your recommendation, fixes with their commit SHAs, uncommitted fixes, skipped findings, open questions, and check results.

Then ask the user how to handle each Critical and refactor finding. Run focused checks on each chosen fix, then commit it the same way. The caller decides if full verification is needed.
