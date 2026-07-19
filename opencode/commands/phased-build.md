---
description: Implement selected phases with delegated builds and review gates
agent: plan
subtask: false
---

Orchestrate selected phases from the Plan primary agent. Builders own all edits, plan updates, and commits. You own builder context, all verification, and review gates. Never implement or commit work yourself.

Usage: `/phased-build <plan-path> <phase-selector>`

- Plan: `$1`
- Phases: `$2`
- Full input: `$ARGUMENTS`
- Accept `2`, `1,3`, `2-4`, or `all-incomplete`.
- Ask for missing or ambiguous arguments. The user must select the phases.

# Rules

- Use `builder` for general work and `frontend-builder` for frontend work.
- Split mixed phases by assigned builder. Give each builder the entire phase, but assign a narrow work unit.
- Do not run code review between builder work units or after individual commits. Review the complete phase only after its implementation and verification pass.
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
- Create one `[orchestrator] Verify Phase N` todo per phase by default. Add a work-unit verification todo only when a multi-unit phase has a distinct focused command that provides earlier feedback. Never create separate work-unit and phase todos for the same commands or coverage.
- Each phase or final review item MUST begin with the exact reviewer name: `[code-review]` or `[security-review]`.
- Final verification MUST name `[orchestrator]`; plan cleanup MUST name the builder that will perform it.

Use concrete labels such as:

- `[builder] Phase 2: implement API persistence`
- `[frontend-builder] Phase 2: implement settings UI`
- `[orchestrator] Verify Phase 2`
- `[code-review] Review completed Phase 2`
- `[security-review] Review the completed branch`
- `[orchestrator] Run final acceptance criteria`
- `[builder] Record final evidence and delete the plan`

Ask the user to confirm the list. Update it if needed. During execution, keep one todo in progress and mark a phase complete only when the plan records completion.

# 3. Hand off, build, and verify

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

After each builder return:

1. Verify the commit exists and contains only declared work.
2. If more work units remain and a distinct focused check would provide useful early feedback, run the narrowest command that covers this work unit. Otherwise, proceed to the phase verification without creating or running a separate work-unit check.
3. If a focused check fails, resume the same builder with the exact command, relevant output, and a concrete correction request. The builder applies the fix and commits without running verification.
4. Rerun that focused check yourself. Repeat until it passes or a blocking decision requires the user.

Before a later phase, rerun the preceding completed phase's verification yourself. If it fails, make no changes and ask the user whether to select that phase for repair.

Stop if a builder needs a pre-existing dirty path.

# 4. Review the completed phase

After every work unit in a phase is implemented and any distinct focused verification passes:

1. Run the phase's exact verification criteria once. This single run also satisfies work-unit verification when the commands or coverage are the same. Resolve failures through the responsible builder and rerun only after a fix.
2. Collect the complete ordered commit list from the phase's starting commit through its latest implementation or fix commit.
3. Invoke `code-review` once for the whole phase. Limit review to that commit range and the complete phase requirements. Exclude unrelated history and dirty changes.

Apply this code-review gate:

- Critical (`C`), High (`H`), or Question (`Q`): stop all work. Show the findings, possible solutions, and your recommendation. Ask the user how to proceed. Do not fix Medium or Low findings while blocked.
- Medium (`M`) or Low (`L`) only: group all findings by responsible builder, resume each builder once, and have it create a separate atomic fix commit without running verification.
- No findings: continue.

After the user answers a blocking review item, send the decision and all remaining findings to the responsible builder. Have the phase's designated builder record any accepted risk in the plan and commit it separately.

After review fixes, run the exact phase verification yourself. Add a focused check only when it is distinct and needed to diagnose the fixes; never run the same command twice in one verification cycle. Then rerun one phase-level review over the full ordered commit list. Do not invoke code review for individual implementation or fix commits. Continue until no findings remain. Never dismiss a finding without a fix, explicit user acceptance, or reviewer confirmation that it is invalid.

# 5. Complete non-final phases

After a non-final phase passes exact verification and phase-level review:

1. Give its designated builder the orchestrator's verification evidence and instruct it to mark the phase `[x] COMPLETE` with the date, command, and result. The builder must not rerun verification.
2. Have the builder commit only the state update.
3. Verify the plan and complete the phase todo.

Keep the actual final phase `[~] IN PROGRESS` after its phase-level review until every final gate passes.

# 6. Final gates

Run these gates only when the selected work includes the actual last phase and all earlier phases are complete.

1. Run every project acceptance criterion yourself. Builders fix failures and commit atomically without running verification; rerun the failed criteria yourself.
2. Find the merge base with the resolved main or master branch.
3. Invoke `code-review` on all committed branch changes against the full plan. Apply the code-review gate above: batch Medium and Low findings by responsible builder; ask the user about Critical, High, and Questions.
4. Invoke `security-review` on the same branch range. Review security only.

Fix every actionable security finding, including `SEC-C`, `SEC-H`, `SEC-M`, and `SEC-L`. Batch findings by responsible builder, have the builder commit them atomically without running verification, and verify the fixes yourself. Do not ask the user merely because a security finding is Critical or High.

Send `SEC-Q` items to the appropriate builder to investigate from repository evidence. Ask the security reviewer to report external unknowns as residual testing gaps rather than questions. Never invent security assumptions.

Do not invoke scoped code review for individual final-gate, code-review-fix, or security-fix commits.

After builders finish a batch of final-gate fixes, rerun all project acceptance criteria, the full branch code review, and the full security review. Continue until both reviews have no actionable findings and every criterion passes.

# 7. Delete the completed plan

After all final gates pass:

1. Resume the final phase's designated builder, give it the orchestrator's verification and review evidence, and have it mark the final phase complete without rerunning verification.
2. Confirm that all phases are complete and no blocking question remains.
3. Delete the plan instead of committing a standalone final-state update.
4. Inspect status and diff, stage only the deletion, and create one atomic cleanup commit.
5. Record the deletion commit SHA. The plan must not remain in the repository.

# 8. Stop, resume, and report

When blocked, leave the phase and todo in progress. Report the phase, commit SHAs, review IDs, and verification results. Ask concise numbered questions with recommended answers. Resume the saved builder, orchestrator verification, and phase-review loop after the user responds.

When selected work finishes, report completed phases, verification, all commit SHAs, phase-level reviews, final code and security reviews, project acceptance results, accepted risks, and remaining phases. Leave the todo list accurate. Do not push.
