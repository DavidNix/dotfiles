---
description: Implement selected phases with delegated builds and review gates
agent: plan
subtask: false
---

Orchestrate selected phases from the Plan primary agent. Subagents own all edits, tests, plan updates, and commits. Never implement or commit work yourself.

Usage: `/phased-build <plan-path> <phase-selector>`

- Plan: `$1`
- Phases: `$2`
- Full input: `$ARGUMENTS`
- Accept `2`, `1,3`, `2-4`, or `all-incomplete`.
- Ask for missing or ambiguous arguments. The user must select the phases.

# Rules

- Use `builder` for general work and `frontend-builder` for frontend work.
- Split mixed phases into general and frontend units. Build and review each unit separately.
- Use `code-review` after every implementation or fix commit. Review only that unit's commits and phase requirements.
- Run phases and work units sequentially. They share a worktree, plan state, and history.
- Resume the same builder task for fixes and final verification.
- Preserve pre-existing work. Never revert, overwrite, stage, or commit unrelated changes.
- Never push, amend, skip hooks, force Git operations, or create empty commits.
- Keep the plan until all phases pass every final gate. Then delete it and commit the deletion.

# 1. Preflight

1. Read the full plan and repository instructions such as `AGENTS.md`.
2. Expand the selector in plan order. Verify that each phase exists.
3. Require confirmation before repeating a completed phase.
4. Check dependencies and statuses. Ask the user to select any incomplete prerequisite.
5. Resolve blocking `[NEEDS CLARIFICATION]` items before work begins.
6. Inspect the branch, status, staged changes, recent commits, and default branch.
7. Refuse to work on `main` or `master`. Stop during a merge, rebase, cherry-pick, or revert.
8. Record HEAD and every staged, unstaged, and untracked path. Give this baseline to each subagent.
9. Resolve the comparison base from `origin/HEAD`, `origin/main`, `origin/master`, local `main`, then local `master`. Do not fetch unless asked.

If selected work needs a path that was already dirty, stop before editing and ask how to proceed. Ignore unrelated dirty paths.

# 2. Confirm todos

Before invoking a subagent, use the todo tool to list:

- Each selected phase, including implementation, scoped review, verification, and state update.
- Separate general and frontend units for mixed phases.
- Final branch code review, security review, and plan cleanup when the selection completes the actual last phase.

Ask the user to confirm the list. Update it if needed. During execution, keep one todo in progress and mark a phase complete only when the plan records completion.

# 3. Build and commit

Choose the appropriate builder for each work unit. Give it:

- The plan path, full phase text, relevant goals, constraints, interfaces, and acceptance criteria.
- Repository instructions, assigned scope, exclusions, starting commit, and dirty-path baseline.
- Instructions to read the full plan and load `ai-tdd` when present.
- Instructions to set the phase to `[~] IN PROGRESS` before coding and include that update in the first implementation commit.
- Instructions to run focused tests, linters, formatters, type checks, and relevant phase verification.
- Instructions to inspect status, diff, and recent commit style; stage only its work; and make one atomic commit.
- Instructions to return the commit SHA, changed paths, commands, results, and blockers.

Before a later phase, have its builder rerun the preceding completed phase's verification. If it fails, make no changes and ask the user whether to select that phase for repair.

Stop if a builder needs a pre-existing dirty path.

# 4. Review each work unit

After each implementation or fix commit:

1. Verify the commit and confirm it contains only declared work.
2. Invoke `code-review` with the unit's ordered commit list.
3. Limit review to those commits against their immediate parent and the selected phase's requirements. Exclude unrelated history and dirty changes.

Apply this code-review gate:

- Critical (`C`), High (`H`), or Question (`Q`): stop all work. Show the findings, possible solutions, and your recommendation. Ask the user how to proceed. Do not fix Medium or Low findings while blocked.
- Medium (`M`) or Low (`L`) only: resume the same builder, fix every finding, verify the fixes, and create a separate atomic commit.
- No findings: continue.

After the user answers a blocking review item, resume the same builder with the decision and all remaining findings. Record any accepted risk in the plan and commit it separately.

Review the full ordered commit list after each fix. Continue until no findings remain. Never dismiss a finding without a fix, explicit user acceptance, or reviewer confirmation that it is invalid.

# 5. Complete non-final phases

After all units in a non-final phase pass review, resume its builder and run the exact phase verification. On failure, fix, commit, and return to review. On success:

1. Mark the phase `[x] COMPLETE` with the date, command, and result.
2. Commit only the state update.
3. Verify the plan and complete the phase todo.

Keep the actual final phase `[~] IN PROGRESS` until every final gate passes.

# 6. Final gates

Run these gates only when the selected work includes the actual last phase and all earlier phases are complete.

1. Run every project acceptance criterion. Builders fix failures, verify them, commit atomically, and pass scoped code review.
2. Find the merge base with the resolved main or master branch.
3. Invoke `code-review` on all committed branch changes against the full plan. Apply the code-review gate above: fix Medium and Low findings; ask the user about Critical, High, and Questions.
4. Invoke `security-review` on the same branch range. Review security only.

Fix every actionable security finding, including `SEC-C`, `SEC-H`, `SEC-M`, and `SEC-L`. Route each finding to `builder` or `frontend-builder`, verify the fix, and commit it atomically. Do not ask the user merely because a security finding is Critical or High.

Send `SEC-Q` items to the appropriate builder to investigate from repository evidence. Ask the security reviewer to report external unknowns as residual testing gaps rather than questions. Never invent security assumptions.

Every security-fix commit must pass scoped `code-review`. Its Critical, High, and Question findings still require user input; its Medium and Low findings are fixed automatically.

After any final-gate fix, rerun the full branch code review, full security review, and all project acceptance criteria. Continue until both reviews have no actionable findings and every criterion passes.

# 7. Delete the completed plan

After all final gates pass:

1. Resume the final builder and mark the final phase complete in its working tree with verification evidence.
2. Confirm that all phases are complete and no blocking question remains.
3. Delete the plan instead of committing a standalone final-state update.
4. Inspect status and diff, stage only the deletion, and create one atomic cleanup commit.
5. Record the deletion commit SHA. The plan must not remain in the repository.

# 8. Stop, resume, and report

When blocked, leave the phase and todo in progress. Report the phase, commit SHAs, review IDs, and verification results. Ask concise numbered questions with recommended answers. Resume the saved builder and review loop after the user responds.

When selected work finishes, report completed phases, verification, all commit SHAs, scoped reviews, final code and security reviews, project acceptance results, accepted risks, and remaining phases. Leave the todo list accurate. Do not push.
