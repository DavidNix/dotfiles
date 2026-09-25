---
description: Implement selected phases from a file or GitHub issue hierarchy with delegated builds and review gates
subtask: false
---

Orchestrate selected phases from a file or GitHub parent issue. Builders own tests, implementation, commits, and focused verification of their assigned changes. When TDD is warranted, instruct the builder to load `ai-tdd` and complete its full cycle in one session. You specify checks, confirm evidence, and own reviews and completion decisions. After the last selected phase and its fixes, run full verification yourself immediately before the final reviews. Delegate implementation rather than writing code yourself.

Fix actionable findings within the selected scope as they arise, including Medium and Low findings. Do not create follow-up files, issues, or a deferred fix pass; do not wait for the user to ask for fixes.

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
- Keep the orchestrator's model and reasoning settings inherited from the invoking session. Implementation builders use their configured low-reasoning variant; resolve cross-cutting design decisions before handing them work.
- Split mixed phases by assigned builder. Give each builder the entire phase but a narrow work unit.
- Review each non-final phase once, after its implementation and focused verification. The last selected phase gets no phase-level review; the final gate review covers it. Do not review individual commits or review a phase again after fixes.
- Run phases and work units sequentially. They share a worktree, plan state, and history.
- Start each work unit in a fresh builder session by omitting `task_id`, including review and final-gate fixes. Keep the full test/implementation/verification cycle in that session. Resume a task to finish or correct that assignment; start new assignments in new sessions.
- Preserve pre-existing work. Never revert, overwrite, stage, or commit unrelated changes.
- Never push, amend, skip hooks, force Git operations, or create empty commits.
- File mode keeps the plan until all phases are complete and the final gate passes, then a builder deletes it in a cleanup commit.
- GitHub mode retains the issue hierarchy as history, closes completed phase issues, and closes the parent only when all managed phases are complete and the final gate passes.

## Focused work units

- Break broad phases into smaller work units when they contain distinct, independently verifiable outcomes. You may do this without approval while preserving phase scope, dependencies, and acceptance criteria. Keep a simple phase as one unit.
- Give each unit one concrete outcome, relevant files and interfaces, resolved design decisions, explicit exclusions, and exact targeted checks. The complete phase is context; the assigned slice is the builder's deliverable. Do not make the builder rediscover architecture or choose between unresolved interface contracts.
- Keep tightly coupled schema and behavior changes together. Each unit owns its tests, implementation, and verification in one session and one commit. Avoid splitting by individual file, function, or TDD stage.
- Keep units under the original phase number in the todo list and handoffs. A phase completes only after all its units pass. Splitting adds no per-unit reviews; retain the existing phase and final review gates.
- If a builder encounters a blocking design question, have it return the specific question and evidence promptly. Resolve it yourself or refine the assignment before resuming that builder, rather than leaving it to explore alternatives indefinitely.

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

- Label every item `[agent-type] Phase N: <brief phase outcome>`, using the actual phase number. Derive the title from the phase's name and outcome so the list explains what each phase delivers. Use `[agent-type] Final: <check and project subject>` for the selected-range gate.
- Include the agent type exactly once: `builder`, `frontend-builder`, `orchestrator`, `code-review`, `security-review`, or `comment-pruner`. Omit issue IDs, duplicated owners, and other prefixes.
- Create one item per work unit: implement, verify, and commit. TDD, when warranted, is internal to that builder assignment. Keep backend and frontend assignments separate when they need different builders.
- Add one code-review item per non-final phase. The final code review covers the last selected phase, so it needs no separate phase-review item.
- End with four items: orchestrator full verification, final code review, final security review, and final comment pruning. The two final reviews and comment pruning run concurrently after full verification; list order does not make them sequential.
- Keep descriptions to roughly 4–8 words after the prefix. Name the feature or behavior: `Persist completed classifications`, not `Implement storage to GREEN, verify, and commit`. Omit workflow boilerplate such as RED/GREEN, test-writing, verification, and commits from builder titles; those remain assignment requirements.
- Review titles must name the phase's subject, such as `Review classification storage and reader safety`, never just `Review changes`. If a phase has multiple work units, retain its recognizable subject and briefly distinguish each slice. Fix titles name the affected behavior rather than generic `Fix findings`. Put exact commands, prerequisites, acceptance criteria, issue references, and evidence in handoffs and the plan.
- Handle evidence submission and confirmation, commits, status updates, issue closure, and plan cleanup within the existing items. Do not add separate test-writing, verification, commit, or handoff todos.

Example for five phases of a candidate-matching plan:

```text
[builder] Phase 1: Store classifications and protect readers
[code-review] Phase 1: Review classification storage and reader safety
[builder] Phase 2: Return structured classification reasons
[code-review] Phase 2: Review classification reason contracts
[builder] Phase 3: Bound AI work and maintain heartbeats
[code-review] Phase 3: Review AI limits and heartbeats
[builder] Phase 4: Screen candidate-job pairs in sweeps
[code-review] Phase 4: Review candidate sweeps and pair screening
[builder] Phase 5: Run the scheduled matching pipeline
[orchestrator] Final: Verify the candidate-matching workflow
[code-review] Final: Review the candidate-matching implementation
[security-review] Final: Audit candidate-matching security
[comment-pruner] Final: Prune candidate-matching code comments
```

Keep exactly one todo in progress while executing and mark completed only after evidence confirmation, including the required commit for builder items. Keep assignment failures within the existing builder item. Triage review findings before assigning fixes. Group actionable findings and verification failures by builder type and add one item per fix work unit as they arise. For example: `[builder] Phase 2: Correct classification reason handling`. Do not create speculative, per-finding, repeat-review, or re-verification items.

Preserve completed history on resume without reopening or re-verifying it. If the user defers phases, remove their unstarted todos and move the final gate to the last remaining selected phase; leave deferred phases pending in the plan. Remove the newly final phase's review item only if it has not started; retain reviews already run and let an active review finish once. If that phase was already complete, preserve its completion record and record final-gate evidence separately instead of reopening it. Proceed without repeating the tool-backed list in chat or asking for approval unless scope or assignment is ambiguous.

# 4. Mark active and hand off

Choose the appropriate builder for each work unit.

Before the first builder starts a phase:

- File mode: instruct the builder to change the phase to `[~] IN PROGRESS` before coding and include that plan update in its implementation commit. Commit the status separately only when parallel agents could duplicate work.
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
- Fix actionable discoveries within the assigned scope as they arise and verify them with focused checks. Report discoveries outside the assignment to the orchestrator for triage before proceeding to the next work unit.
- Repository instructions, known files or symbols, prior-phase decisions and verification evidence, starting commit, and dirty-path baseline.
- Backend-specific status instructions. In GitHub mode state that issue persistence is orchestrator-owned and already updated.
- The exact commit message or commit-message intent.
- Your TDD decision and brief reason under the policy below. When warranted, explicitly instruct: "Load the `ai-tdd` skill before implementation and follow its appropriate mode through RED and GREEN in this assignment." Otherwise state that TDD is not warranted and assign suitable validation. Each builder runs its assigned checks and fixes LSP diagnostics in changed files.
- The verification to run for this work unit: only focused tests, builds, linters, format or type checks, migration/integration checks, or browser/manual QA directly relevant to its changes. Supply exact commands with flags, arguments, environment variables, working directories, prerequisites, and expected results; do not invent missing commands. For mixed phases, assign shared integration checks to the builder whose work completes the dependency. Builders must not run a phase-wide or repository-wide suite merely to finish a phase or fix; obey any explicit repository-required checks. Reserve full-project verification for the orchestrator immediately before the final reviews.
- Instructions to inspect status, diff, and recent history; stage only assigned paths; create one atomic commit after assigned checks pass; and return the commit SHA, changed paths, verification results (exact commands, exit codes, and relevant output, including RED/GREEN evidence when TDD applies), LSP issues fixed, and blockers. Put a concise evidence summary in the commit message so the trail survives the session. A successful assignment must return its commit, not merely promise to commit later.

Supply this context directly. Do not make builders read the full plan or rediscover existing decisions. Tell them the orchestrator maintains the only todo list.

## Decide whether TDD is warranted

Make this decision per work unit, including review and final-gate fixes:

- **Use `ai-tdd`:** testable application behavior, features, bug fixes, and behavior-preserving application refactors. Specify Feature Mode or Bug Fix Mode as appropriate.
- **Do not require TDD:** Terraform, Ansible, other infrastructure/provisioning/deployment work, Go `main()` functions and entrypoint wiring, documentation, or non-behavioral configuration changes. These are pre-authorized exceptions; do not ask for permission to skip TDD. Use relevant formatting, lint, syntax, validation, plan/dry-run, build, or smoke checks instead, subject to repository requirements and execution permissions.
- **Mixed work:** apply TDD to the application logic that warrants it and validation to the exempt parts. Logic in helpers called by Go `main()` can warrant TDD; do not add tests for `main()` itself or extract wiring solely to manufacture a TDD target.

The builder owns the full skill workflow in one session: observe meaningful behavioral failures before implementing, reach GREEN, and run the assigned checks. RED is intermediate evidence, not a separate assignment, parent approval gate, or commit requirement. Keep any refactoring within assigned scope. Commit the verified work once; do not split tests and implementation across agents or create test-only RED commits.

After each builder returns, confirm that the commit exists, contains only declared work, and that its verification evidence is present and consistent with the committed tree. Record its SHA, session ID, TDD decision, and evidence in the plan or issue completion comment. Before the final gate, do not re-run builder verification yourself. Keep its item incomplete and resume the same builder for missing evidence or unexpected failed checks. Launch new work in a fresh assignment with its own TDD decision. Wait until every work unit in the phase is implemented and verified. Stop if a builder needs a pre-existing dirty path.

## TDD-ordering recovery

If TDD was warranted but implementation preceded RED, preserve the work and record the actual chronology as a TDD process deviation. Post-hoc failures against stashed or reverted production changes are regression sensitivity evidence, never test-first evidence. Resume the builder for missing regression coverage or checks; do not reconstruct history or create extra stage assignments. This command authorizes continuing after recording the deviation without asking the user to accept it again. New behavioral fixes still follow `ai-tdd` when warranted. Record an ordering-only review finding as accepted under this policy. A historical ordering deviation alone must not keep a verified phase open; failed checks and unresolved blocking findings still do.

# 5. Confirm and review the completed phase

After every work unit in a phase is implemented:

1. Confirm the builder's reported focused verification evidence against its assigned checks and applicable phase criteria. Reserve any repository-wide criteria for the final gate. Do not re-run builder verification.
2. If evidence is missing or shows a failure within an assignment, resume that builder with a concrete correction request. Have it run missing checks, rerun failed checks, and check behavior affected by its fix before reporting its commit. Use a fresh assignment for new fixes, applying the TDD policy above. Do not repeat unaffected successful checks.
3. Collect the ordered commit list from the phase's starting commit through its latest implementation or verification-fix commit.
4. Invoke `code-review` exactly once for the whole phase. Skip this review for the last selected phase; the final gate review covers it. Limit review to that commit range and the complete phase requirements. Exclude unrelated history and dirty changes.

Handle historical TDD-ordering findings under the recovery policy above. Apply this code-review gate to the remaining findings:

- Critical (`C`): stop all work. Show only Critical findings, possible solutions, and your recommendation. Ask the user how to proceed.
- High (`H`): apply the best repository-consistent solution automatically. Prefer the reviewer's recommendation when it preserves approved architecture, public interfaces, and phase scope. If every credible fix needs a major architectural change or large refactor, promote the finding to Critical and ask the user.
- Question (`Q`): investigate from repository evidence and choose the safest reversible answer. Promote it to Critical only when it needs a major architectural change, large design refactor, irreversible public-interface change, or cannot be resolved safely.
- Medium (`M`) or Low (`L`): fix automatically in the current review-fix pass before completing the phase.
- No findings: continue.

Only Critical findings may produce user questions. When blocked, retain the findings for the builder fix pass. After the user answers, group the decision and remaining actionable findings by responsible builder.

Record accepted risk:

- File mode: have the phase's designated builder record the accepted risk in the plan and commit it separately.
- GitHub mode: record the accepted risk in one phase issue comment with `gh issue comment "$phase" --body-file -`.

Group all actionable review findings by builder type into scoped fix work units, with your TDD decision and targeted checks. Use one fresh builder per work unit to fix, verify, and commit, instructing it to load `ai-tdd` when warranted. Do not enumerate automatically handled findings in orchestrator chat. After builders return fixes and evidence, do not repeat unaffected phase checks or the phase review. Each finding must have a verified fix, explicit user acceptance, or reviewer confirmation that it is invalid before completing the phase.

# 6. Complete non-final phases

After a non-final phase passes focused verification and its review findings are fixed, accepted, or confirmed invalid, record the date, command and result, review outcome, and relevant commit range.

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

Run the final gate after the last selected phase's implementation and focused checks finish, regardless of whether that is the project's final phase. Do not reopen completed phases when the selection changes.

1. Find the merge base with the resolved main or master branch and record the full selected commit range and its ending SHA, not just the last phase. Exclude unrelated history and dirty changes.
2. Run the complete verification suite yourself immediately before dispatching final reviews: tests, builds, linters, type checks, and project acceptance. Do not delegate this to a verification builder or run it at the end of each phase. Record criteria dependent on unselected phases as unmet, not passed. If verification fails, assign focused builder fixes, rerun failed and affected checks yourself until green, and update the ending SHA before dispatching reviews.
3. Dispatch `code-review`, `security-review`, and `comment-pruner` concurrently against the same pinned commit range. Give the reviews the complete selected plan and scope. In GitHub mode provide the parent body, every managed phase body, and relevant evidence comments. Reviewers must inspect the pinned committed snapshot rather than the worktree while pruning is in progress. Wait for all three results and triage Critical code-review findings before committing pruning changes or assigning fixes; only the pruner may edit comments during the reviews. After any Critical decision, inspect and commit its comment-only edits before assigning review fixes, as described below.

Apply the phase code-review gate to final code-review findings. Critical (`C`) findings still stop work and require the user's decision; automatically fix other actionable findings, including Medium and Low.

Fix every actionable security finding, including `SEC-C`, `SEC-H`, `SEC-M`, and `SEC-L`. Do not ask the user merely because a security finding is Critical or High. Include `SEC-Q` investigation in the responsible builder's assignment when repository evidence can resolve it. Treat external unknowns as residual testing gaps. Never invent security assumptions.

After resolving blocking questions, combine final code-review and actionable security findings by builder type into scoped fix work units. Use one fresh builder and one atomic fix commit per work unit. Supply the grouped findings, TDD decision, and focused checks; explicitly instruct the builder to load `ai-tdd` when warranted. If no fixes remain, proceed directly to finalization.

After builders commit fixes, rerun checks affected by the fixes yourself until green. Do not repeat unaffected successful checks, the full suite by default, or either review. Resume the same builder for an incomplete fix; use a fresh assignment for new work with TDD when warranted. Finalize only when applicable verification passes and every in-scope actionable finding is fixed and verified, explicitly accepted by the user, or confirmed invalid. Keep actual blockers and unverified gaps visible; never mark them as passed.

## Final comment pruning

Invoke `comment-pruner` once in a fresh session concurrently with the two final reviews, after orchestrator full verification passes. Limit its assignment to code comments introduced or modified by the selected phases and pre-final fixes. Supply the pinned commit range, changed paths, repository instructions, and dirty-path baseline. Instruct it to follow its comment-only rules, preserve behavior and functional directives, and leave unrelated work untouched. It must not implement review findings or commit while reviews are running. Builders assigned post-review fixes should keep their own comments concise and purposeful.

After all three agents return and any Critical code-review decision is resolved, have the pruner report its changed paths and a concise summary of comments removed or shortened. Inspect the diff to confirm the edits are comment-only and preserve required explanations. Run any checks affected by the edits yourself, then have the pruner inspect status, diff, and recent history, stage only its authorized changes, and commit them. Skip the commit if nothing changed. Record the summary, verification evidence, and commit SHA when present with the final-gate evidence. Complete the existing comment-pruning todo only after confirming that evidence; do not repeat either final review.

# 8. Finalize the plan

File mode:

1. Mark the last selected phase complete yourself with evidence already collected. If it was already complete before a scope reduction, append final-gate evidence without changing its completion record. Do not rerun verification.
2. Confirm all selected phases are complete and no blocking question remains.
3. If any phase remains incomplete or deferred, retain the plan, stage only its status update, commit it, and stop finalization here. Otherwise invoke the last selected phase's designated builder to delete the plan instead of committing a standalone final-status update. Identify your final status edit as an authorized dirty change.
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

When blocked, leave the current phase active in its selected backend and keep the current todo in progress. Report the target, phase, work unit, commit SHAs, session IDs, review IDs, and verification results. Ask concise numbered questions with recommended answers only for genuinely unclear or blocking decisions. Resume the saved builder for the same assignment after the user responds; start new work units in fresh sessions and preserve the current single-pass review gate.

When selected work finishes, report the plan path or parent issue URL, completed phases, a brief verification/review result, and remaining phases or gaps. Keep it to a few short bullets. Store detailed commands, outputs, commit SHAs, and issue evidence in the plan or completion comments rather than repeating them in chat. Before deleting a completed file plan, include its completion evidence in the cleanup commit message. Leave the todo list accurate. Do not push.
