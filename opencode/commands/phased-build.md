---
description: Implement selected phases from a file or GitHub issue hierarchy with delegated builds and review gates
agent: build
subtask: false
---

Orchestrate selected phases from a file or GitHub parent issue. Builders own implementation, commits, and all verification of their own work. You own builder context, the review gates, and completion decisions. Never implement code or re-run builder verification.

# 0. Resolve the target

Usage: `/phased-build <plan-target> <phase-selector>`

- Target: `$1`
- Phases: `$2`
- Full input: `$ARGUMENTS`
- Accept selectors `2`, `1,3`, `2-4`, or `all-incomplete`.
- A Markdown path inside the current repository selects file mode.
- A positive issue number, `#<number>`, or GitHub issue URL selects GitHub mode and must identify an existing parent issue. Strip a leading `#` before passing the number to `gh`.
- Infer the mode when the user names a file or issue. Do not ask them to choose a mode they already indicated.
- Ask only when the target or selector is missing, conflicting, or ambiguous. The user must select the phases; never choose them silently.

File mode: resolve the supplied path and require the plan to exist inside the current repository.

GitHub mode:

1. Load the `gh-issues` skill.
2. Run `gh auth status` and `gh repo view --json nameWithOwner,hasIssuesEnabled,viewerPermission,url` before the first mutation.
3. Treat a bare number as an issue in the current repository. If an issue URL points elsewhere, ask whether that repository is intentional before mutating it.
4. Read the parent with `gh issue view "$parent" --json number,title,body,state,stateReason,parent,subIssues,subIssuesSummary,comments,url` and read every managed phase issue in full.
5. Require `<!-- phased-plan:v1 -->` in the parent and `<!-- phased-plan-phase:v1 -->` in each managed phase. Leave unrelated sub-issues untouched.
6. Ask before proceeding if the issue is a sub-issue, the parent is closed, status metadata conflicts with issue state, or unrelated sub-issues make finalization ambiguous.

# 1. Shared rules

- Use `builder` for general work and `frontend-builder` for frontend work.
- Split mixed phases by assigned builder. Give each builder the entire phase but a narrow work unit.
- Review each non-final phase once, after its implementation and verification. The last selected phase gets no phase-level review; the final gate review covers it. Do not review individual commits or review a phase again after fixes.
- Run phases and work units sequentially. They share a worktree, plan state, and history.
- Resume the same builder task for fixes and builder-owned file-plan updates.
- Preserve pre-existing work. Never revert, overwrite, stage, or commit unrelated changes.
- Never push, amend, skip hooks, force Git operations, or create empty commits.
- File mode keeps the plan until the final gate passes, then a builder deletes it in a cleanup commit.
- GitHub mode retains the issue hierarchy as history, closes completed phase issues, and closes the parent only after the final gate passes.

# 2. Preflight

1. Read repository instructions such as `AGENTS.md`.
2. Read the full selected plan target. In GitHub mode this means the parent, every managed phase body, and relevant completion comments, not only the selected phases.
3. Expand the selector in recorded phase order and verify that every selected phase exists.
4. Derive status from the plan body. In GitHub mode require completed phases closed with reason `completed` and pending or active phases open.
5. If the user selects a completed phase, stop and recommend a new follow-up phase. Proceed only after explicit confirmation that overrides immutable plan history; never reopen or rewrite it implicitly.
6. Check dependencies and statuses. Ask the user to select any incomplete prerequisite.
7. Resolve blocking `[NEEDS CLARIFICATION]` items before the affected work begins.
8. Inspect the branch, status, staged changes, recent commits, and default branch.
9. Refuse to work on `main` or `master`. Stop during a merge, rebase, cherry-pick, or revert.
10. Record HEAD and every staged, unstaged, and untracked path. Give this baseline to each subagent.
11. Resolve the comparison base from `origin/HEAD`, `origin/main`, `origin/master`, local `main`, then local `master`. Do not fetch unless asked.

If selected work needs a dirty path, stop and ask how to proceed. Ignore unrelated dirty paths. In file mode treat a pre-existing dirty plan file as a conflict because builders and the orchestrator must update it.

## Mandatory Execution Checklist

After reading the plan target and all managed phase content, use `todowrite` to create the full execution checklist for every requested phase before delegating work or editing implementation files. This must be the actual tool-backed task list, never a Markdown checklist in a chat response.

Never collapse a phase into one todo. Make every builder handoff, verification gate, and code review a separate actionable todo. Prefix each with its phase/issue and a single owner:

- `P1 | Builder | ...`
- `P1 | Code Review | ...`
- `Final | Orchestrator | ...`

Use the actual phase numbers. In GitHub mode include the issue ID (for example `P1 #77 | Builder | ...`). Use Frontend Builder where appropriate. Give each todo one owner.

Expand each incomplete phase's protocol into these todos:

1. Builder: load `ai-tdd`; for test-required phases write tests and behavior-free compiling stubs, prove RED, then implement to GREEN. Run the phase's own verification (tests, builds, linters, type checks, acceptance) and report evidence.
2. Orchestrator: confirm the evidence and commit, then run the code-review gate once.
3. Code Review: review the full phase once; Builder resolves findings in one pass.
4. Orchestrator: record evidence and complete the phase.

The last selected phase gets no phase-level review; the final gate review covers it. Expand builder implementation into extra todos for distinct deliverables. Preserve verification commands verbatim, including flags, arguments, environment variables, and working-directory requirements. Invent nothing absent from the plan or repository instructions.

Add FINAL todos, run at the end of the user-selected range:

- Builder: run the complete verification suite across the selected range.
- Code Review: review the complete selected range once.
- Security Review: review the complete selected range.
- Orchestrator: on verification failure, dispatch builder fixes and have the verification builder rerun only the failed commands.
- Orchestrator: combine review findings by responsible builder into one fix pass, with test-first handoffs for bugs.
- Orchestrator: record acceptance and review evidence, and complete the selected plan only when every gate passes.

Execution ownership:

- Builders run all verification of their own work and report evidence.
- The orchestrator confirms evidence, runs the review gates, and makes completion decisions; it never re-runs builder verification.
- RED must be observed by the builder via `ai-tdd` before committing implementation.
- At the end the orchestrator dispatches a builder to run the full verification suite in parallel with the final code and security reviews.
- Do not add another phase verification pass after phase-review fixes.

Keep the task list current:

- Keep exactly one todo in progress while executing.
- Mark completed only after actual evidence, never intent.
- On verification failure add a builder-fix todo and have the builder rerun only the failed command; never rerun a full suite.
- Mark conditional review-fix work cancelled if there are no findings.
- Preserve completed phase history on resume; do not reopen or reverify it.
- Do not replace the expanded checklist with phase-level summary todos.
- A request to "do all phases" requires the full checklist up front, including later phases and the final gate review.

# 3. Confirm todos

Before invoking a subagent, list the todos:

- Start each implementation or fix item with the exact builder name: `[builder]` or `[frontend-builder]`.
- Name the assigned builder in each mixed-phase item.
- Never make review findings orchestrator or per-finding todos. Aggregate automatically handled findings into one builder fix todo per responsible builder without severity details in the label.
- Create exactly one `[builder] Verify Phase N` todo per phase. Do not create work-unit, regression, or re-verification todos.
- Create exactly one phase-review todo beginning with `[code-review]`. The last selected phase gets no phase-level review. Final review items must begin with `[code-review]` or `[security-review]`.
- Run final `[builder]` verification, `[code-review]`, and `[security-review]` todos in parallel against the same range. Wait for all three before dispatching fixes.
- Name final verification `[builder]` and final acceptance `[orchestrator]`.
- Name file cleanup with the builder that deletes the plan; name GitHub issue completion `[orchestrator]`.
- Keep the existing verification or review todo in progress while handling its failures or findings. Do not add repeat-review or re-verification todos.

Use concrete labels:

- `[builder] Phase 2: implement API persistence`
- `[frontend-builder] Phase 2: implement settings UI`
- `[builder] Verify Phase 2`
- `[code-review] Review completed Phase 2`
- `[builder] Run final verification suite`
- `[security-review] Review the completed range`
- `[code-review] Review the completed range`
- `[orchestrator] Run final acceptance criteria`
- `[builder] Delete the completed plan` in file mode
- `[orchestrator] Close completed plan issues` in GitHub mode

Present the list and proceed when it follows the user's selected phases and the assignments are clear. Ask only when an assignment or scope boundary is ambiguous. Keep one todo in progress and mark a phase complete only when its selected backend records completion.

# 4. Mark active and hand off

Choose the appropriate builder for each work unit.

Before the first builder starts a phase:

- File mode: instruct the builder to change the phase to `[~] IN PROGRESS` before coding and include that plan update in its first implementation commit. Commit the status separately only when parallel agents could duplicate work.
- GitHub mode: you edit the current phase body, changing only its status to `[~] IN PROGRESS`, before delegation. Builders must not edit or comment on plan issues.

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
- Backend-specific status instructions. In GitHub mode state that issue persistence is orchestrator-owned and already updated.
- The exact commit message or commit-message intent.
- An instruction to load `ai-tdd` and follow it: for test-required phases write tests and behavior-free compiling stubs, prove RED, then implement to GREEN. Builders run all verification of their own work (tests, builds, linters, format checks, type checks, and the phase's acceptance commands) and report the evidence. They may use LSP and must fix every diagnostic in changed files.
- Instructions to stage only assigned paths, create one atomic commit, and return the commit SHA, changed paths, verification results (RED/GREEN output and command outputs), LSP issues fixed, and blockers.

Supply this context directly. Do not make builders read the full plan or rediscover existing decisions.

After each builder returns, confirm that the commit exists, contains only declared work, and that the reported verification evidence is present and consistent. Do not re-run builder verification. Wait until every work unit in the phase is implemented. Stop if a builder needs a pre-existing dirty path.

# 5. Confirm and review the completed phase

After every work unit in a non-final phase is implemented:

1. Confirm the builder's reported verification evidence against the phase's exact criteria. Do not re-run builder verification.
2. If the evidence shows a failure, instruct the responsible builder to rerun the exact failed command with a concrete correction request. After its fix commit, have it rerun only that command until it passes. Do not rerun commands that already passed.
3. Collect the ordered commit list from the phase's starting commit through its latest implementation or verification-fix commit.
4. Invoke `code-review` exactly once for the whole phase. Skip this review for the last selected phase; the final gate review covers it. Limit review to that commit range and the complete phase requirements. Exclude unrelated history and dirty changes.

Apply this code-review gate:

- Critical (`C`): stop all work. Show only Critical findings, possible solutions, and your recommendation. Ask the user how to proceed.
- High (`H`): apply the best repository-consistent solution automatically. Prefer the reviewer's recommendation when it preserves approved architecture, public interfaces, and phase scope. If every credible fix needs a major architectural change or large refactor, promote the finding to Critical and ask the user.
- Question (`Q`): investigate from repository evidence and choose the safest reversible answer. Promote it to Critical only when it needs a major architectural change, large design refactor, irreversible public-interface change, or cannot be resolved safely.
- Medium (`M`) or Low (`L`): group all findings silently by responsible builder for one fix pass without verification.
- No findings: continue.

Only Critical findings may produce user questions. When blocked, retain other findings for the later builder fix pass. After the user answers, group the decision and all remaining findings by responsible builder.

Record accepted risk:

- File mode: have the phase's designated builder record the accepted risk in the plan and commit it separately.
- GitHub mode: record the accepted risk in one phase issue comment with `gh issue comment "$phase" --body-file -`.

Send each builder all of its review findings in one pass. Do not enumerate automatically handled findings in orchestrator chat; report only the aggregate fix commit. After builders commit fixes, do not rerun phase verification or code review. Treat each finding as resolved by a fix, explicit user acceptance, or reviewer confirmation that it is invalid. The final gate review is the backstop.

# 6. Complete non-final phases

After a non-final phase passes exact verification and its review findings are fixed or accepted, record the date, command and result, review outcome, and relevant commit range.

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

Keep the last selected phase `[~] IN PROGRESS` and, in GitHub mode, open until the final gate passes.

# 7. Final gate

Run the final gate at the end of the user-selected range, after the last selected phase completes, regardless of whether that is the project's final phase.

1. Find the merge base with the resolved main or master branch.
2. Dispatch three subagents concurrently over the same selected commit range:
   - A `[builder]` that runs the complete verification suite: tests, builds, linters, type checks, and project acceptance.
   - `code-review` reviewing implementation.
   - `security-review` reviewing security only.
   Give all three the complete selected plan and branch range. In GitHub mode provide the parent body, every managed phase body, and relevant evidence comments. Wait for all three results.
3. On verification failure, dispatch builder fixes and have the verification builder rerun only the failed commands until green. Never rerun a full suite.

Apply the phase code-review gate to final code-review findings. Resolve Critical findings with the user; handle every other severity automatically.

Fix every actionable security finding, including `SEC-C`, `SEC-H`, `SEC-M`, and `SEC-L`. Do not ask the user merely because a security finding is Critical or High. Include `SEC-Q` investigation in the responsible builder's assignment when repository evidence can resolve it. Treat external unknowns as residual testing gaps. Never invent security assumptions.

After resolving blocking questions, combine all code-review and security-review findings by responsible builder. Send each builder one final fix assignment with a test-first handoff for bugs, and have it create one atomic fix commit.

After builders commit fixes, do not rerun the full verification suite, security review, or code review. Treat each finding as resolved by a fix, explicit user acceptance, or reviewer confirmation that it is invalid, then finalize the selected backend.

# 8. Finalize the plan

File mode:

1. Mark the last selected phase complete yourself with evidence already collected. Do not rerun verification.
2. Confirm all selected phases are complete and no blocking question remains.
3. Invoke the last selected phase's designated builder to delete the plan instead of committing a standalone final-status update. Tell it that your final status edit is the expected authorized dirty change.
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

When selected work finishes, report the plan path or parent issue URL, completed phases, builder verification evidence, the final verification suite result, all commit SHAs, phase-level reviews, final code and security reviews, project acceptance results, accepted risks, and remaining phases. In GitHub mode include each affected phase URL and final issue states. Leave the todo list accurate. Do not push.