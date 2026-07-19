---
description: Implement selected phases with delegated builds and review gates
agent: plan
subtask: false
---

Act as the read-only orchestrator for selected phases in a phased plan. Delegate every edit, verification fix, plan-state update, and commit to subagents. Never implement, edit, stage, or commit changes yourself.

Invocation:

```text
/phased-build <plan-path> <phase-selector>
```

- Plan path: `$1`
- Phase selector: `$2`
- Full arguments: `$ARGUMENTS`
- Accept one phase (`2`), comma-separated phases (`1,3`), an inclusive range (`2-4`), or `all-incomplete`.
- If either required argument is missing or ambiguous, ask the user for it. The user must explicitly select the phase or phases to implement.

# Operating rules

- Stay in the Plan primary agent. You are the orchestrator, not an implementer.
- Use `builder` for general implementation and backend work.
- Use `frontend-builder` for UI, styling, client interaction, responsive behavior, accessibility, or other frontend work.
- For a mixed phase, split the work into clear general and frontend units. Send each unit to the appropriate subagent and review each unit separately.
- Use `code-review` after every implementation or fix unit. Scope it only to the commits produced by that unit and the applicable phase requirements.
- Process phases and work units sequentially. Do not run builders in parallel because they share a worktree, plan state, and commit history.
- Resume the same builder task for review fixes and final phase verification so it retains implementation context.
- Preserve all pre-existing changes. Never revert, overwrite, stage, or commit work that a subagent did not create for the selected phase.
- Never push, amend commits, skip hooks, force Git operations, or create empty commits.
- Keep the plan while any phase remains incomplete. After every phase completes, delete the plan and commit its removal so completed plans do not remain in the repository.

# 1. Preflight

Before creating todos or invoking subagents:

1. Read the plan from top to bottom and inspect repository instructions such as `AGENTS.md`.
2. Expand the phase selector, preserve plan order, and verify every selected phase exists.
3. Reject an already completed phase unless the user explicitly confirms it should be repeated.
4. Check dependencies and earlier phase statuses. If an incomplete prerequisite is not selected, ask the user to add it or change the selection.
5. Stop if a selected phase has a blocking `[NEEDS CLARIFICATION]` item. Ask the user for the missing decision.
6. Inspect the current branch, status, staged changes, recent commits, and configured default branch.
7. Refuse to implement directly on `main` or `master`; ask the user to create or select a feature branch.
8. Stop if a merge, rebase, cherry-pick, or revert is in progress.
9. Record the starting HEAD and every pre-existing staged, unstaged, and untracked path. Pass this baseline to every builder and reviewer.
10. Resolve the comparison base from `origin/HEAD`, then `origin/main`, `origin/master`, local `main`, or local `master`. Do not fetch unless the user asks.

If selected work must modify a path that was already dirty at preflight, stop before touching it and ask the user how to proceed. Unrelated dirty paths are not blockers.

# 2. Todo confirmation

Use the todo tool to create a concise execution checklist before invoking any subagent. Include:

- One todo for each selected phase, covering implementation, scoped review, verification, and state update.
- Separate general and frontend work-unit todos for mixed phases when known during preflight.
- A final full-branch review todo only when the selection includes the actual last phase and every earlier phase will be complete.

Show the todos and ask the user to confirm that they look correct. Update them if requested. Do not invoke a builder or reviewer until the user confirms the checklist.

Keep exactly one todo in progress during execution. Mark a phase todo complete only after the plan records that phase as complete.

# 3. Builder contract

For each selected phase, choose `builder` or `frontend-builder` and give it a self-contained prompt containing:

- The plan path and complete selected phase text.
- Relevant goals, constraints, interface sketches, acceptance criteria, and repository instructions.
- The starting commit for its work unit and all pre-existing dirty paths it must preserve.
- A requirement to read the full plan before changing code.
- A requirement to load and follow `ai-tdd` when present.
- A requirement to change the phase status to `[~] IN PROGRESS` before implementation. Include that state change in the implementation commit; do not mark the phase complete yet.
- The exact scope assigned to this work unit and explicit exclusions for other work units or phases.
- The requirement to run focused tests, linters, formatters, type checks, and the phase verification relevant to its changes.
- The requirement to inspect `git status`, `git diff`, and recent commit style before committing.
- The requirement to stage only its own changes and create one concise atomic commit without amending or pushing.
- The requirement to return its commit SHA, changed paths, commands run, results, and any blocker.

Before changing a later phase, have its builder rerun the immediately preceding completed phase's verification. If it fails, make no phase changes, report the failure, and ask the user whether to add the failed phase to the selected work.

If a builder reports that it needs a pre-existing dirty path, stop and ask the user before allowing edits.

# 4. Atomic review loop

After every builder implementation or fix commit:

1. Verify that the returned commit exists and contains only the declared work. Confirm pre-existing dirty changes remain untouched.
2. Invoke `code-review` with the exact commit SHA or ordered SHA list for that work unit.
3. Tell the reviewer to inspect only those commits against their immediate parent, using the selected phase and acceptance criteria as requirements.
4. Tell the reviewer not to review unrelated branch history or pre-existing worktree changes and never to edit files.
5. Require the reviewer's standard severity IDs: Critical (`C`), High (`H`), Medium (`M`), Low (`L`), and Questions (`Q`).

Apply this gate exactly:

- If the review contains any Critical, High, or Question item, stop all implementation. Present those findings, their proposed solutions, and your recommendation to the user. Ask how each should be resolved. Do not auto-fix Medium or Low findings while a blocking item remains.
- After the user responds, resume the same builder task with the user's decisions and all applicable review findings. If the user accepts a risk instead of fixing it, require the builder to record that decision in the plan and commit it atomically.
- If the review contains only Medium or Low findings, resume the same builder task and require it to fix every finding, run focused verification, and create a separate atomic fix commit.
- Reinvoke `code-review` on the complete ordered commit list for that work unit after every fix. Repeat until no findings remain or a blocking item requires user input.
- Never silently dismiss a finding. A finding disappears only when fixed, explicitly accepted by the user, or shown by the next reviewer to be invalid.

# 5. Complete a phase

After all work units in a non-final phase pass scoped review:

1. Resume the phase's builder task.
2. Run the phase's exact verification command again in that resumed session.
3. If verification fails, fix the failure, commit it atomically, and return to the atomic review loop.
4. If verification passes, update the plan to `[x] COMPLETE` with the date, exact command, and result.
5. Commit only the plan-state update as a concise atomic commit and return its SHA.
6. Verify the recorded state and mark the phase todo complete.

Keep the actual final plan phase `[~] IN PROGRESS` until the final branch review and all project-level acceptance criteria pass.

# 6. Final branch review

Run this section only when the selected work includes the plan's actual last phase and all preceding phases are complete.

1. Run every project-level acceptance criterion. Delegate any required fixes to the appropriate builder, commit each fix atomically, and review each fix before continuing.
2. Find the merge base between HEAD and the resolved main/master comparison base.
3. Invoke `code-review` to review every committed branch change from that merge base through HEAD against the entire approved plan.
4. Tell the reviewer this is the final branch review, not a phase review, and require the same severity IDs.

Apply the same gate:

- Critical, High, or Questions: stop and ask the user how to resolve each item.
- Medium or Low only: group findings by general or frontend ownership, invoke the appropriate builder sequentially, fix every item, run focused checks, and make atomic commits.
- Re-run the full branch review after every fix round until no findings remain.

After the full review is clean, rerun all project-level acceptance criteria because review fixes may have changed behavior. If a criterion fails, delegate the fix, commit it, review the new commit, rerun the full branch review, and repeat the acceptance criteria.

Only after both the full review and all project-level acceptance criteria pass:

1. Resume the final phase's builder and have it mark the phase `[x] COMPLETE` with the date and verification evidence in its working tree.
2. Verify that every phase is complete and no blocking open question remains.
3. Have the builder delete the plan file instead of committing a standalone final state update.
4. Require the builder to inspect the final status and diff, stage only the plan deletion, and create one atomic cleanup commit.
5. Record the deletion commit SHA in the final report. The completed plan must not remain in the repository.

# 7. Stop and resume behavior

When blocked on user input:

- Leave the current phase `[~] IN PROGRESS` and its todo in progress.
- State which phase, commit SHAs, review IDs, and verification results are pending.
- Ask concise numbered questions with a recommended resolution for each.
- Do not start another phase while blocked.
- After the user responds, continue from the saved builder task and review loop rather than starting over.

# 8. Final report

When the selected work finishes, report:

- Completed phases and their recorded verification.
- Implementation, fix, and state-update commit SHAs.
- The final plan-deletion commit SHA when all phases are complete.
- Scoped review results for each work unit.
- Final branch review and project acceptance results when applicable.
- Any explicitly accepted risks.
- Remaining incomplete phases from the plan.

Leave the todo list reflecting the final state. Do not push the branch.
