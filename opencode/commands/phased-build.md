---
description: Implement selected phases from a file or GitHub issue hierarchy with delegated builds and review gates
agent: build
subtask: false
---

Orchestrate selected phases from a file or GitHub parent issue. Builders own implementation, commits, and assigned phase verification. You specify their checks, confirm evidence, and own reviews and completion decisions. After the last selected phase, run full verification yourself and coordinate fixes. Delegate implementation rather than writing code yourself.

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
- File mode keeps the plan until all phases are complete and the final gate passes, then a builder deletes it in a cleanup commit.
- GitHub mode retains the issue hierarchy as history, closes completed phase issues, and closes the parent only when all managed phases are complete and the final gate passes.

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

# 3. Execution checklist

Before delegation, use `todowrite` to create one flat, orchestrator-owned list covering all selected phases and the final gate. Do not create separate subagent lists or umbrella phase todos.

- Label every item `[agent-type] Phase N: Short action`, using the actual phase number. Use `[agent-type] Final: Short action` for the selected-range gate.
- Include the agent type exactly once: `builder`, `frontend-builder`, `orchestrator`, `code-review`, or `security-review`. Omit issue IDs, duplicated owners, and other prefixes.
- Create one implementation item per builder work unit, including its assigned verification. Keep backend and frontend assignments separate when they need different builders. Do not split implementation and verification into separate todos or handoffs.
- Add one code-review item per non-final phase. The final code review covers the last selected phase, so it needs no separate phase-review item.
- End with three items: orchestrator full verification, final code review, and final security review. The two final reviews run in parallel against the same range; list order does not make them sequential.
- Keep labels brief. Put exact commands, prerequisites, acceptance criteria, issue references, and evidence in handoffs and the plan, not todo labels.
- Handle evidence confirmation, commits, status updates, issue closure, and plan cleanup within the existing items, without bookkeeping todos.

Example for three selected phases with mixed work in phase 2:

```text
[builder] Phase 1: Implement token storage
[code-review] Phase 1: Review changes
[builder] Phase 2: Implement job grants
[frontend-builder] Phase 2: Update forms and legal copy
[code-review] Phase 2: Review changes
[builder] Phase 3: Implement plain-text delivery
[orchestrator] Final: Run full verification
[code-review] Final: Review completed changes
[security-review] Final: Review completed changes
```

Keep exactly one todo in progress while executing and mark completed only after evidence. Keep implementation failures within the existing builder item. When review findings or final verification failures require another assignment, add one concise fix item per responsible builder, such as `[frontend-builder] Phase 2: Fix review findings` or `[builder] Final: Fix verification and review findings`. Do not create speculative, per-finding, repeat-review, or re-verification items.

Preserve completed history on resume without reopening or re-verifying it. If the user defers phases, remove their unstarted todos and move the final gate to the last remaining selected phase; leave deferred phases pending in the plan. Remove the newly final phase's review item only if it has not started; retain reviews already run and let an active review finish once. If that phase was already complete, preserve its completion record and record final-gate evidence separately instead of reopening it. Proceed without repeating the tool-backed list in chat or asking for approval unless scope or assignment is ambiguous.

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
- Your decision whether to use `ai-tdd`, with a brief reason. Normally use it for testable behavior changes and bug fixes; it may be unnecessary for documentation or non-behavioral changes. Respect explicit plan and repository requirements. When selected, instruct the builder to load and follow it, proving RED before implementing to GREEN. Skipping `ai-tdd` does not waive assigned verification. Run assigned checks in the same implementation assignment and fix LSP diagnostics in changed files.
- The verification to run for this work unit: tests, builds, linters, format or type checks, migration/integration checks, or browser/manual QA as required by the plan and repository. Supply exact commands with flags, arguments, environment variables, working directories, prerequisites, and expected results; do not invent missing commands. For mixed phases, assign shared integration checks to the builder whose work completes the dependency. Keep checks phase-scoped and reserve full-project verification for your final gate, except checks explicitly required by repository instructions.
- Instructions to stage only assigned paths, create one atomic commit, and return the commit SHA, changed paths, verification results (command outputs and RED/GREEN when assigned), LSP issues fixed, and blockers.

Supply this context directly. Do not make builders read the full plan or rediscover existing decisions. Tell them the orchestrator maintains the only todo list.

After each builder returns, confirm that the commit exists, contains only declared work, and that the reported verification evidence is present and consistent. Before the final gate, do not re-run builder verification yourself. Keep its item incomplete and resume the same builder for missing evidence or failed checks. Wait until every work unit in the phase is implemented and verified. Stop if a builder needs a pre-existing dirty path.

# 5. Confirm and review the completed phase

After every work unit in a phase is implemented:

1. Confirm the builder's reported verification evidence against the phase's exact criteria. Do not re-run builder verification.
2. If evidence is missing or shows a failure, resume the responsible builder with a concrete correction request. Have it run missing checks, rerun failed checks, and check behavior affected by its fix before reporting its commit. Do not repeat unaffected successful checks.
3. Collect the ordered commit list from the phase's starting commit through its latest implementation or verification-fix commit.
4. Invoke `code-review` exactly once for the whole phase. Skip this review for the last selected phase; the final gate review covers it. Limit review to that commit range and the complete phase requirements. Exclude unrelated history and dirty changes.

Apply this code-review gate:

- Critical (`C`): stop all work. Show only Critical findings, possible solutions, and your recommendation. Ask the user how to proceed.
- High (`H`): apply the best repository-consistent solution automatically. Prefer the reviewer's recommendation when it preserves approved architecture, public interfaces, and phase scope. If every credible fix needs a major architectural change or large refactor, promote the finding to Critical and ask the user.
- Question (`Q`): investigate from repository evidence and choose the safest reversible answer. Promote it to Critical only when it needs a major architectural change, large design refactor, irreversible public-interface change, or cannot be resolved safely.
- Medium (`M`) or Low (`L`): group all findings silently by responsible builder for one fix pass.
- No findings: continue.

Only Critical findings may produce user questions. When blocked, retain other findings for the later builder fix pass. After the user answers, group the decision and all remaining findings by responsible builder.

Record accepted risk:

- File mode: have the phase's designated builder record the accepted risk in the plan and commit it separately.
- GitHub mode: record the accepted risk in one phase issue comment with `gh issue comment "$phase" --body-file -`.

Send each builder all of its review findings in one pass, with your `ai-tdd` decision and targeted checks for the fixes. Do not enumerate automatically handled findings in orchestrator chat. After builders return fixes and evidence, do not repeat unaffected phase checks or the phase review. Treat each finding as resolved by a verified fix, explicit user acceptance, or reviewer confirmation that it is invalid. The final gate is the backstop.

# 6. Complete non-final phases

After a non-final phase passes exact verification and its review findings are fixed or accepted, record the date, command and result, review outcome, and relevant commit range.

File mode:

1. Mark the phase `[x] COMPLETE` yourself with the completion evidence. Do not rerun verification.
2. Inspect the diff, stage only the plan, and commit the state update.
3. Verify the plan and update the existing todos without adding a completion item.

GitHub mode:

1. Add the completion evidence as a phase comment with quoted stdin.
2. Edit the phase body so its status contains the same `[x] COMPLETE` record, preserving all other content.
3. Close it with `gh issue close "$phase" --reason completed`.
4. Read it back with `gh issue view "$phase" --json body,state,stateReason,parent,url` and require the completed marker, `CLOSED`, reason `COMPLETED`, and the expected parent.
5. Do not create a commit for issue state.

Keep the last selected phase `[~] IN PROGRESS` and, in GitHub mode, open until the final gate passes, unless it was already complete before a scope reduction.

# 7. Final gate

Run the final gate after the last selected phase's implementation and assigned checks finish, regardless of whether that is the project's final phase. Do not reopen completed phases when the selection changes.

1. Find the merge base with the resolved main or master branch and record the full selected commit range and its ending SHA, not just the last phase. Exclude unrelated history and dirty changes.
2. Run the complete verification suite yourself: tests, builds, linters, type checks, and project acceptance. Do not delegate this to a verification builder. Run the repository-wide suite, but exclude acceptance criteria that depend on deferred work and record those exclusions rather than claiming full project completion.
3. Dispatch `code-review` and `security-review` concurrently against the same recorded range. Give both the complete selected plan and scope. In GitHub mode provide the parent body, every managed phase body, and relevant evidence comments. Wait for both results before assigning fixes; do not change reviewed code while either review is running.

Apply the phase code-review gate to final code-review findings. Resolve Critical findings with the user; handle every other severity automatically.

Fix every actionable security finding, including `SEC-C`, `SEC-H`, `SEC-M`, and `SEC-L`. Do not ask the user merely because a security finding is Critical or High. Include `SEC-Q` investigation in the responsible builder's assignment when repository evidence can resolve it. Treat external unknowns as residual testing gaps. Never invent security assumptions.

After resolving blocking questions, combine verification failures and all code-review and security-review findings by responsible builder. Send each builder one final fix assignment with your `ai-tdd` decision and assigned targeted checks, and have it create one atomic fix commit.

After builders commit fixes, rerun failed verification commands and checks affected by the fixes yourself until green. Do not repeat unaffected successful checks, the full suite by default, or either review. Resume the responsible builder if a check still fails. Finalize only when applicable verification passes and every finding is fixed and verified, explicitly accepted, or confirmed invalid. Keep actual blockers and unverified gaps visible; never mark them as passed.

# 8. Finalize the plan

File mode:

1. Mark the last selected phase complete yourself with evidence already collected. If it was already complete before a scope reduction, append final-gate evidence without changing its completion record. Do not rerun verification.
2. Confirm all selected phases are complete and no blocking question remains.
3. If any phase remains incomplete or deferred, retain the plan, stage only its status update, commit it, and stop finalization here. Otherwise invoke the last selected phase's designated builder to delete the plan instead of committing a standalone final-status update. Tell it that your final status edit is the expected authorized dirty change.
4. Have the builder inspect status and diff, stage only the deletion, and create one atomic cleanup commit.
5. Record the deletion commit SHA. The completed plan file must not remain in the repository.

GitHub mode:

1. Add the final phase's completion evidence as a comment, edit its body to `[x] COMPLETE`, and close it with reason `completed` without rerunning verification. If it was already complete before a scope reduction, add only the final-gate evidence comment; leave its completed body and closed state unchanged.
2. Confirm every selected phase is closed as completed and no blocking question remains.
3. Add one parent comment summarizing selected-range acceptance, phase and final reviews, implementation and fix commits, accepted risks, residual gaps, and remaining phases.
4. If any managed phase remains incomplete or deferred, leave it and the parent open and stop finalization here. Otherwise, if unrelated open sub-issues make closing the parent ambiguous, ask before closing it. Leave unrelated issues untouched.
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

When selected work finishes, report the plan path or parent issue URL, completed phases, a brief verification/review result, and remaining phases or gaps. Keep it to a few short bullets. Store detailed commands, outputs, commit SHAs, and issue evidence in the plan or completion comments rather than repeating them in chat. Before deleting a completed file plan, include its completion evidence in the cleanup commit message. Leave the todo list accurate. Do not push.
