---
description: Implement selected phases from a file or GitHub issue hierarchy with delegated builds and review gates
agent: build
subtask: false
---

Orchestrate selected phases from an explicit file or existing GitHub parent issue. Builders own implementation edits and commits. You own builder context, all verification, review gates, and completion decisions. Never implement code.

# 0. Resolve the target

Usage: `/phased-build <plan-target> <phase-selector>`

- Target: `$1`
- Phases: `$2`
- Full input: `$ARGUMENTS`
- Accept selectors `2`, `1,3`, `2-4`, or `all-incomplete`.
- A Markdown path that resolves inside the current repository selects file mode.
- A positive issue number, `#<number>`, or GitHub issue URL selects GitHub mode and must identify an existing parent issue. Strip a leading `#` before passing the number to `gh`.
- Infer the mode when the user clearly names a file or GitHub issue anywhere in the request. Do not ask them to choose a mode they already indicated.
- Ask only when the target or selector is missing, conflicting, or genuinely ambiguous. The user must select the phases; never choose them silently.

For file mode, resolve the supplied path and require the Markdown plan to exist inside the current repository.

For GitHub mode:

1. Load the `gh-issues` skill.
2. Run `gh auth status` and `gh repo view --json nameWithOwner,hasIssuesEnabled,viewerPermission,url` before the first mutation.
3. Treat a bare number as an issue in the current repository. If an issue URL points elsewhere, ask whether that repository is intentional before mutating it.
4. Read the parent with `gh issue view "$parent" --json number,title,body,state,stateReason,parent,subIssues,subIssuesSummary,comments,url` and read every managed phase issue in full.
5. Require `<!-- phased-plan:v1 -->` in the parent and `<!-- phased-plan-phase:v1 -->` in each managed phase. Leave unrelated sub-issues untouched.
6. If the supplied issue is a sub-issue, the parent is closed, status metadata conflicts with issue state, or unrelated sub-issues make finalization ambiguous, ask before proceeding.

# 1. Shared rules

- Use `builder` for general work and `frontend-builder` for frontend work.
- Split mixed phases by assigned builder. Give each builder the entire phase, but assign a narrow work unit.
- Run exactly one code review per phase after its implementation and verification pass. Do not review individual commits or review the phase again after fixes.
- Run phases and work units sequentially. They share a worktree, plan state, and history.
- Resume the same builder task for fixes and any builder-owned file-plan update.
- Preserve pre-existing work. Never revert, overwrite, stage, or commit unrelated changes.
- Never push, amend, skip hooks, force Git operations, or create empty commits.
- File mode keeps the plan until every final gate passes, then deletes it in a builder cleanup commit.
- GitHub mode retains the issue hierarchy as history, closes completed phase issues, and closes the parent only after every final gate passes.

# 2. Preflight

1. Read repository instructions such as `AGENTS.md`.
2. Read the full selected plan target. In GitHub mode this means the parent plus every managed phase body and relevant completion comments, not only the selected phases.
3. Expand the selector in recorded phase order and verify that every selected phase exists.
4. Derive status from the plan body. In GitHub mode, also require completed phases to be closed with reason `completed` and pending or active phases to be open.
5. If the user selects a completed phase, stop and recommend a new follow-up phase. Proceed only after explicit confirmation that overrides immutable plan history; never reopen or rewrite it implicitly.
6. Check dependencies and statuses. Ask the user to select any incomplete prerequisite.
7. Resolve blocking `[NEEDS CLARIFICATION]` items before the affected work begins.
8. Inspect the branch, status, staged changes, recent commits, and default branch.
9. Refuse to work on `main` or `master`. Stop during a merge, rebase, cherry-pick, or revert.
10. Record HEAD and every staged, unstaged, and untracked path. Give this baseline to each subagent.
11. Resolve the comparison base from `origin/HEAD`, `origin/main`, `origin/master`, local `main`, then local `master`. Do not fetch unless asked.

If selected work needs a path that was already dirty, stop before editing and ask how to proceed. Ignore unrelated dirty paths. In file mode, treat a pre-existing dirty plan file as a conflict because builders and the orchestrator must update it.

# 3. Confirm todos

Before invoking a subagent, use the todo tool to list:

- Each implementation or fix item MUST begin with the exact builder name: `[builder]` or `[frontend-builder]`.
- Each mixed-phase item MUST name its assigned builder.
- Review findings must never become orchestrator or per-finding todos. Aggregate automatically handled findings into one builder fix todo per responsible builder without severity details in the label.
- Create exactly one `[orchestrator] Verify Phase N` todo per phase. Do not create work-unit, regression, or re-verification todos.
- Create exactly one phase-review todo beginning with `[code-review]`. Final review items MUST begin with `[code-review]` or `[security-review]`.
- Run final `[code-review]` and `[security-review]` todos in parallel against the same branch range. Wait for both before dispatching fixes.
- Final verification MUST name `[orchestrator]`.
- File cleanup MUST name the builder that will delete the plan. GitHub issue completion MUST name `[orchestrator]`.
- Keep the existing verification or review todo in progress while handling its failures or findings. Do not add repeat-review or re-verification todos.

Use concrete labels such as:

- `[builder] Phase 2: implement API persistence`
- `[frontend-builder] Phase 2: implement settings UI`
- `[orchestrator] Verify Phase 2`
- `[code-review] Review completed Phase 2`
- `[security-review] Review the completed branch`
- `[code-review] Review the completed branch`
- `[orchestrator] Run final acceptance criteria`
- `[builder] Delete the completed plan` in file mode
- `[orchestrator] Close completed plan issues` in GitHub mode

Present the list and proceed when it follows the user's selected phases and the assignments are clear. Ask only when an assignment or scope boundary is genuinely ambiguous. During execution, keep one todo in progress and mark a phase complete only when its selected backend records completion.

# 4. Mark active and hand off

Choose the appropriate builder for each work unit.

Before the first builder starts a phase:

- File mode: instruct the designated builder to change the phase to `[~] IN PROGRESS` before coding and include that plan update in its first implementation commit. Commit the status separately only when parallel agents could duplicate work.
- GitHub mode: you edit the entire current phase body, changing only its status to `[~] IN PROGRESS`, before delegation. Builders must not edit or comment on plan issues.

For GitHub mode, preserve the rest of the body and use quoted stdin without a temporary file:

```bash
gh issue edit "$phase" --body-file - <<'EOF'
<!-- phased-plan-phase:v1 -->
**Status:** [~] IN PROGRESS
...
EOF
```

Give each builder:

- The plan target and entire current phase verbatim, including status, outcome, changes, dependencies, exclusions, and verification criteria. Never summarize or omit part of the phase.
- Relevant project goals, non-goals, constraints, interface sketches, and acceptance criteria.
- The exact assigned work unit and excluded scope. For a mixed phase, give every builder the same complete phase followed by its specific slice.
- Repository instructions, known files or symbols, prior-phase decisions and verification evidence, starting commit, and dirty-path baseline.
- Backend-specific status instructions. In GitHub mode, state that issue persistence is orchestrator-owned and already updated.
- The exact commit message or commit-message intent.
- An explicit reminder that verification criteria are context only: builders must not run tests, builds, linters, format checks, type checks, acceptance commands, or other verification. They may use LSP and must fix every diagnostic in changed code files.
- Instructions to stage only assigned paths, create one atomic commit, and return the commit SHA, changed paths, LSP issues fixed, and blockers.

Supply this context directly. Do not make builders read the full plan or rediscover existing decisions.

After each builder returns, verify that the commit exists and contains only declared work. Do not run work-unit verification. Wait until every work unit in the phase is implemented. Stop if a builder needs a pre-existing dirty path.

# 5. Verify and review the completed phase

After every work unit in a phase is implemented:

1. Run the phase's exact verification criteria under its single verification todo.
2. If verification fails, resume the responsible builder with the exact failed command, relevant output, and a concrete correction request. After its fix commit, rerun only the failed command under the same todo until it passes. Do not rerun commands that already passed.
3. Collect the complete ordered commit list from the phase's starting commit through its latest implementation or verification-fix commit.
4. Invoke `code-review` exactly once for the whole phase. Limit review to that commit range and the complete phase requirements. Exclude unrelated history and dirty changes.

Apply this code-review gate:

- Critical (`C`): stop all work. Show only Critical findings, possible solutions, and your recommendation. Ask the user how to proceed.
- High (`H`): choose and apply the best repository-consistent solution automatically. Prefer the reviewer's recommendation when it preserves approved architecture, public interfaces, and phase scope. If every credible fix requires a major architectural change or large refactor, promote the finding to Critical and ask the user.
- Question (`Q`): investigate from repository evidence and choose the safest reversible answer. Promote it to Critical only when it requires a major architectural change, large design refactor, irreversible public-interface change, or cannot be resolved safely.
- Medium (`M`) or Low (`L`): group all findings silently by responsible builder for one fix pass without verification.
- No findings: continue.

Only Critical findings may produce user questions. When blocked, retain other findings for the later builder fix pass. After the user answers, group the decision and all remaining findings by responsible builder.

Record accepted risk according to the backend:

- File mode: have the phase's designated builder record the accepted risk in the plan and commit it separately.
- GitHub mode: you record the accepted risk in one phase issue comment using `gh issue comment "$phase" --body-file -`.

Send each builder all of its review findings in one pass. Do not enumerate automatically handled findings in orchestrator chat; report only the aggregate fix commit. After builders commit fixes, do not rerun phase verification or code review. Treat each finding as resolved by a fix, explicit user acceptance, or reviewer confirmation that it is invalid. The final branch review is the backstop.

# 6. Complete non-final phases

After a non-final phase passes exact verification and its single review's findings are fixed or accepted, record the date, command and result, review outcome, and relevant commit range.

File mode:

1. Mark the phase `[x] COMPLETE` yourself with the completion evidence. Do not rerun verification.
2. Inspect the diff, stage only the plan, and commit the state update.
3. Verify the plan and complete the phase todo.

GitHub mode:

1. Add the completion evidence as a phase comment with quoted stdin.
2. Edit the phase body so its status contains the same `[x] COMPLETE` record, preserving all other content.
3. Close it with `gh issue close "$phase" --reason completed`.
4. Read it back with `gh issue view "$phase" --json body,state,stateReason,parent,url` and require the completed marker, `CLOSED`, reason `COMPLETED`, and the expected parent.
5. Do not create a commit for issue state.

Keep the actual final phase `[~] IN PROGRESS` and, in GitHub mode, open after its single phase review and fixes until every final gate passes.

# 7. Final gates

Run these gates only when selected work includes the actual last phase and all earlier phases are complete.

1. Run every project acceptance criterion once under the single final-verification todo. If a criterion fails, have the responsible builder fix it, then rerun only that failed criterion under the same todo until it passes.
2. Find the merge base with the resolved main or master branch.
3. Invoke `code-review` and `security-review` concurrently on all committed branch changes from the same merge base. Give both agents the complete selected plan and branch range. In GitHub mode, provide the parent body, every managed phase body, and relevant evidence comments. Tell `code-review` to review implementation and `security-review` to review security only. Wait for both results.

Apply the phase code-review gate to final code-review findings. Resolve Critical findings with the user; handle every other severity automatically.

Fix every actionable security finding, including `SEC-C`, `SEC-H`, `SEC-M`, and `SEC-L`. Do not ask the user merely because a security finding is Critical or High. Include `SEC-Q` investigation in the responsible builder's assignment when repository evidence can resolve it. Treat external unknowns as residual testing gaps. Never invent security assumptions.

After resolving blocking questions, combine all code-review and security-review findings by responsible builder. Send each builder one final fix assignment and have it create one atomic fix commit without running verification.

After builders commit fixes, do not rerun project acceptance, security review, or code review. Treat each finding as resolved by a fix, explicit user acceptance, or reviewer confirmation that it is invalid, then finalize the selected backend.

# 8. Finalize the plan

File mode:

1. Mark the final phase complete yourself with evidence already collected. Do not rerun verification.
2. Confirm all phases are complete and no blocking question remains.
3. Invoke the final phase's designated builder to delete the plan instead of committing a standalone final-status update. Tell it that your final status edit is the expected authorized dirty change.
4. Have the builder inspect status and diff, stage only the deletion, and create one atomic cleanup commit.
5. Record the deletion commit SHA. The completed plan file must not remain in the repository.

GitHub mode:

1. Add the final phase's completion evidence as a comment, edit its body to `[x] COMPLETE`, and close it with reason `completed` without rerunning verification.
2. Confirm every managed phase is closed as completed and no blocking question remains.
3. If unrelated open sub-issues make closing the parent ambiguous, ask before closing it. Otherwise leave unrelated issues untouched.
4. Add one parent comment summarizing project acceptance, phase and final reviews, implementation and fix commits, accepted risks, and residual gaps.
5. Close the parent with `gh issue close "$parent" --reason completed`.
6. Read the parent back with `gh issue view "$parent" --json state,stateReason,subIssuesSummary,url` and require `CLOSED` with reason `COMPLETED`.
7. Retain all issues as project history. Do not delete issues or create a cleanup commit.

# 9. GitHub command contract

Use only compatible native commands for issue lifecycle operations:

```bash
gh issue view "$issue" --json number,title,body,state,stateReason,parent,subIssues,subIssuesSummary,comments,url
gh issue edit "$issue" --body-file -
gh issue comment "$issue" --body-file -
gh issue close "$issue" --reason completed
gh issue close "$issue" --reason "not planned"
gh issue reopen "$issue"
```

Before a sub-issue operation, verify that `gh issue create --help` exposes `--parent` and `gh issue edit --help` exposes `--add-sub-issue`. If absent, stop and report that `gh` must be upgraded. Never emulate a native relationship with a Markdown task list.

# 10. Stop, resume, and report

When blocked, leave the current phase active in its selected backend and keep the current todo in progress. Report the target, phase, commit SHAs, review IDs, and verification results. Ask concise numbered questions with recommended answers only for genuinely unclear or blocking decisions. Resume the saved builder and current single-pass gate after the user responds.

When selected work finishes, report the plan path or parent issue URL, completed phases, verification, all commit SHAs, phase-level reviews, final code and security reviews, project acceptance results, accepted risks, and remaining phases. In GitHub mode include each affected phase URL and final issue states. Leave the todo list accurate. Do not push.
