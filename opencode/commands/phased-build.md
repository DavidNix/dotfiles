---
description: Implement selected phases with delegated builds and review gates
agent: plan
subtask: false
---

Orchestrate selected phases from the Plan primary agent. Builders own implementation edits, delegated plan updates, and their commits. You own builder context, all verification, review gates, and phase-completion updates. Never implement code. Commit only non-final phase-completion updates yourself.

Usage: `/phased-build <plan-path> <phase-selector>`

- Plan: `$1`
- Phases: `$2`
- Full input: `$ARGUMENTS`
- Accept `2`, `1,3`, `2-4`, or `all-incomplete`.
- Ask for missing or ambiguous arguments. The user must select the phases.

# Rules

- Use `builder` for general work and `frontend-builder` for frontend work.
- Split mixed phases by assigned builder. Give each builder the entire phase, but assign a narrow work unit.
- Run exactly one code review per phase after its implementation and verification pass. Do not review individual commits or review the phase again after fixes.
- Run phases and work units sequentially. They share a worktree, plan state, and history.
- Resume the same builder task for fixes and plan updates.
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

- Each implementation or fix item MUST begin with the exact builder name: `[builder]` or `[frontend-builder]`.
- Each mixed-phase item MUST name its assigned builder.
- Create exactly one `[orchestrator] Verify Phase N` todo per phase. Do not create work-unit, regression, or re-verification todos.
- Create exactly one phase-review todo beginning with `[code-review]`. Final review items MUST begin with `[code-review]` or `[security-review]`.
- Final verification MUST name `[orchestrator]`; plan cleanup MUST name the builder that will perform it.
- Keep the existing verification or review todo in progress while handling its findings. Do not add repeat-review or re-verification todos.

Use concrete labels such as:

- `[builder] Phase 2: implement API persistence`
- `[frontend-builder] Phase 2: implement settings UI`
- `[orchestrator] Verify Phase 2`
- `[code-review] Review completed Phase 2`
- `[security-review] Review the completed branch`
- `[code-review] Review the completed branch`
- `[orchestrator] Run final acceptance criteria`
- `[builder] Delete the completed plan`

Ask the user to confirm the list. Update it if needed. During execution, keep one todo in progress and mark a phase complete only when the plan records completion.

# 3. Hand off and build

Choose the appropriate builder for each work unit. Give it:

- The plan path and the entire current phase verbatim, including its status, outcome, changes, dependencies, exclusions, and verification criteria. Never summarize or omit part of the phase.
- The relevant project goals, non-goals, constraints, interface sketches, and acceptance criteria needed to understand the phase.
- The exact assigned work unit and excluded scope. For a mixed phase, give every builder the same complete phase followed by its specific slice.
- Repository instructions, known files or symbols, prior-phase decisions and verification evidence, starting commit, and dirty-path baseline.
- Instructions to set the phase to `[~] IN PROGRESS` before coding and include that update in the first implementation commit.
- The exact commit message or commit-message intent.
- An explicit reminder that verification criteria are context only: the builder must not run tests, builds, linters, format checks, type checks, acceptance commands, or other verification. It may use LSP and must fix every diagnostic in changed code files.
- Instructions to stage only assigned paths, create one atomic commit, and return the commit SHA, changed paths, LSP issues fixed, and blockers.

Supply this context directly. Do not make the builder read the full plan or rediscover decisions that the plan or orchestrator already contains.

After each builder return, verify that the commit exists and contains only declared work. Do not run work-unit verification. Wait until every work unit in the phase is implemented.

Stop if a builder needs a pre-existing dirty path.

# 4. Review the completed phase

After every work unit in a phase is implemented:

1. Run the phase's exact verification criteria under its single verification todo.
2. If verification fails, resume the responsible builder with the exact failed command, relevant output, and a concrete correction request. After its fix commit, rerun only the failed command under the same todo until it passes. Do not rerun commands that already passed.
3. Collect the complete ordered commit list from the phase's starting commit through its latest implementation or verification-fix commit.
4. Invoke `code-review` exactly once for the whole phase. Limit review to that commit range and the complete phase requirements. Exclude unrelated history and dirty changes.

Apply this code-review gate:

- Critical (`C`), High (`H`), or Question (`Q`): stop all work. Show the findings, possible solutions, and your recommendation. Ask the user how to proceed. Do not fix Medium or Low findings while blocked.
- Medium (`M`) or Low (`L`) only: group all findings by responsible builder for one fix pass without verification.
- No findings: continue.

After the user answers a blocking review item, group the decision and all remaining findings by responsible builder. Have the phase's designated builder record any accepted risk in the plan and commit it separately.

Send each builder all of its review findings in one pass. After the builders commit their fixes, do not rerun phase verification or code review. Treat each finding as resolved by a fix, explicit user acceptance, or reviewer confirmation that it is invalid, then move on. The final branch review is the backstop for phase-review fixes.

# 5. Complete non-final phases

After a non-final phase passes exact verification and its single review's findings are fixed or accepted:

1. Mark the phase `[x] COMPLETE` yourself with the date, command, result, and review outcome. Do not rerun verification.
2. Inspect the diff, stage only the plan, and commit the state update.
3. Verify the plan and complete the phase todo.

Keep the actual final phase `[~] IN PROGRESS` after its single phase review and fixes until every final gate passes.

# 6. Final gates

Run these gates only when the selected work includes the actual last phase and all earlier phases are complete.

1. Run every project acceptance criterion once under the single final-verification todo. If a criterion fails, have the responsible builder fix it, then rerun only that failed criterion under the same todo until it passes.
2. Find the merge base with the resolved main or master branch.
3. Invoke `security-review` once on all committed branch changes against the full plan. Review security only.

Fix every actionable security finding, including `SEC-C`, `SEC-H`, `SEC-M`, and `SEC-L`. Batch findings by responsible builder and have each builder make one atomic fix commit without running verification. Do not ask the user merely because a security finding is Critical or High.

Send `SEC-Q` items to the appropriate builder to investigate from repository evidence. Ask the security reviewer to report external unknowns as residual testing gaps rather than questions. Never invent security assumptions.

After security findings are fixed or accepted, invoke `code-review` exactly once on the full branch range, including all phase-review and security-review fixes. Apply the code-review gate above: batch Medium and Low findings by responsible builder; ask the user about Critical, High, and Questions.

Send each builder all final code-review findings in one pass. After the builders commit their fixes, do not rerun project acceptance, security review, or code review. Treat each finding as resolved by a fix, explicit user acceptance, or reviewer confirmation that it is invalid, then continue to cleanup.

# 7. Delete the completed plan

After all final gates pass:

1. Mark the final phase complete yourself with the verification and review evidence already collected. Do not rerun verification.
2. Confirm that all phases are complete and no blocking question remains.
3. Invoke the final phase's designated builder to delete the plan instead of committing a standalone final-state update. Tell it that the orchestrator's final status edit is the expected and authorized dirty change to that file.
4. Have the builder inspect status and diff, stage only the deletion, and create one atomic cleanup commit.
5. Record the deletion commit SHA. The plan must not remain in the repository.

# 8. Stop, resume, and report

When blocked, leave the phase and todo in progress. Report the phase, commit SHAs, review IDs, and verification results. Ask concise numbered questions with recommended answers. Resume the saved builder and the current single-pass gate after the user responds.

When selected work finishes, report completed phases, verification, all commit SHAs, phase-level reviews, final code and security reviews, project acceptance results, accepted risks, and remaining phases. Leave the todo list accurate. Do not push.
