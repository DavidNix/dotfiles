---
description: Create or revise an executable phased plan in a file or GitHub issue hierarchy
---

First, load the `writing-clearly-and-concisely` skill (if present) and apply it to every part of the plan.

Use the research and decisions already present in this conversation to create or revise a spec and phased implementation plan that an orchestrator can delegate without drifting. Treat direction after the mode or target as optional. Do not discard or repeat research already completed in the current context.

Do not implement the project. Persist the plan as a file or GitHub issue hierarchy according to the selected creation mode or existing artifact target.

# 0. Resolve the target

New plan: `/phased-plan <file|gh|github> [additional direction]`

Revise a plan: `/phased-plan <plan-target> [additional direction]`

- Mode or target: `$1`
- Full input: `$ARGUMENTS`
- `file` selects creation mode for a new Markdown plan. `gh` and `github` select creation mode for a new parent issue and managed phase sub-issues.
- A Markdown path that resolves inside the current repository selects file mode for that exact artifact. Create it if it does not exist or revise it in place if it does.
- A positive issue number, `#<number>`, or GitHub issue URL selects GitHub revision mode and must identify an existing parent issue. Strip a leading `#` before passing the number to `gh`.
- A creation mode always creates a new artifact. Never silently reuse or revise a similarly named file or issue.
- Infer creation mode when the user clearly asks for a new file or GitHub issue anywhere in the request. Infer revision mode when they clearly name an artifact target. Do not ask them to choose a mode they already indicated.
- If neither a mode nor target is supplied, two choices conflict, or the choice is genuinely ambiguous, ask one concise clarification question. Never invent whether the user wants a file or issue.

For new file mode, derive a concise short kebab-case name from the project goal and create `plans/<short-kebab-case-name>.md` inside the repository. Create `plans/` when needed. If that path already exists, use the first unused numeric suffix such as `-2`; do not overwrite or revise it.

For an explicit file target, resolve the supplied path and require it to stay inside the current repository. Read the entire existing file before revising it.

For GitHub mode:

1. Load the `gh-issues` skill and follow its compatible command and stdin guidance.
2. Run `gh auth status` and `gh repo view --json nameWithOwner,hasIssuesEnabled,viewerPermission,url` before the first mutation.
3. Require issues to be enabled and the viewer to have `WRITE`, `MAINTAIN`, or `ADMIN` permission. Before creating sub-issues, verify that `gh issue create --help` exposes `--parent`; stop and request a `gh` upgrade if it does not.
4. In creation mode, derive a concise, action-oriented parent title from the problem and goals. Create a fresh parent even when a similar issue exists; do not search for or reuse a possible match.
5. In revision mode, treat a bare number as an issue in the current repository. If an issue URL points to another repository, ask whether that repository is intentional before mutating it.
6. In revision mode, read the parent with `gh issue view "$parent" --json number,title,body,state,stateReason,parent,subIssues,subIssuesSummary,comments,url`, then read every managed phase issue in full.
7. If a supplied issue is itself a sub-issue, is closed, or contains sub-issues whose role makes the requested plan ambiguous, ask before proceeding. Do not ask merely because unrelated sub-issues exist; leave them untouched.
8. Preserve an existing parent's title unless the user explicitly asks to change it. Treat its current body as planning input and fold relevant content into the structured spec.

# 1. Purpose

Write a right-sized spec: detailed enough to make scope, sequence, and completion unambiguous, but not so detailed that it pre-writes the implementation.

Prevent these common failures:

- Scope creep: require explicit non-goals.
- Ambiguous completion: require executable acceptance criteria for the project and every phase.
- Silent assumptions: tag guesses instead of inventing details.
- Monolithic delivery: create atomic, independently verifiable phases.
- Over-engineering: sketch only the simplest interfaces required by the acceptance criteria.
- Data-model drift: define persisted or shared data and its evolution before dependent behavior.
- Context loss: make the selected plan artifact sufficient for a fresh agent to resume.

# 2. Draft and clarify before persistence

Use the conversation, repository, an existing artifact when revising, and your judgment to draft the complete parent spec and every phase without interviewing the user. You own the initial recommendations for goals, non-goals, acceptance criteria, and phase order; do not ask the user to author them.

Record reasonable, reversible assumptions under Constraints and Assumptions. State them directly or tag them `[ASSUMED: ...]`.

Use `[NEEDS CLARIFICATION: ...]` only when the answer could materially change:

- Scope or architecture.
- Security or data handling.
- A public interface or irreversible decision.
- The ability to define credible acceptance criteria.

Ask before drafting only when no safe default exists and the answer would reshape the entire plan. Otherwise, finish the draft in memory and ask at most three blocking questions afterward, with a recommended default for each. Do not write the file or mutate any issue until blocking questions have been answered. Questions affecting only a later phase may remain, but that phase cannot start until they are resolved.

Draft all GitHub issue bodies before the first mutation. This minimizes partial hierarchies and makes retries deterministic.

# 3. Revising an existing plan

Treat phase status as an edit boundary in either backend:

- `[x] COMPLETE`: immutable history. Do not remove, rewrite, reorder, renumber, reopen, or alter its verification evidence.
- `[~] IN PROGRESS`: preserve its scope and order while implementation is active. Put new or changed scope in a later phase.
- `[ ] NOT STARTED`: may be removed, rewritten, split, combined, added, or reordered.

In GitHub mode, a completed phase must also be closed with reason `completed`; pending and active phases remain open. If issue state and the body status conflict, ask before changing either one.

If a requested change would alter completed or active work, preserve the locked phase and create one or more pending follow-up phases instead. Explain the substitution in chat; do not ask the user to redesign it when a safe follow-up is clear.

Keep locked phase identifiers stable. Renumber pending phases only when doing so does not change a locked phase's identity or recorded references. Update pending dependencies, project acceptance criteria, architecture, and interface sketches to match revised future work, but never rewrite historical completion evidence.

In GitHub mode, manage only sub-issues containing `<!-- phased-plan-phase:v1 -->`. Leave unrelated sub-issues unchanged. When removing a pending managed phase, detach it with `--remove-parent`, explain the removal in a comment, and close it with reason `not planned`; never delete it. Use the sub-issue priority REST endpoint only when a revision actually changes phase order.

# 4. Required plan content

The shared spec must contain these sections in this order. In file mode they form one Markdown document. In GitHub mode they form the parent issue body, followed by a phase index whose entries link to the managed sub-issues.

## 1. Problem statement

In two to four sentences, state what hurts, for whom, and why it matters now. Do not propose solutions here.

## 2. Goals

Recommend one to six checkable outcomes from the available context.

- Bad: "Improve the API."
- Good: "Keep `/search` p95 latency below 200 ms under the documented benchmark."

## 3. Non-Goals

Recommend one to six plausible expectations that the project deliberately excludes, with a brief reason for each. This section is required and may not be empty.

## 4. Constraints and assumptions

Record the stack, environment, preserved interfaces, timeline, and other hard limits. Tag inferred constraints `[ASSUMED: ...]` and unresolved decisions `[NEEDS CLARIFICATION: ...]`.

## 5. Architecture sketch

Include this section, but add a Mermaid diagram only when the work has at least three interacting components, such as services, queues, external APIs, or distinct layers.

Keep diagrams high-level, with about five to twelve nodes. A single-module change or CRUD endpoint needs no diagram. If an honest diagram needs more than twelve nodes, split the work into smaller phases or a second-level issue hierarchy only when that added hierarchy is necessary.

## 6. Interface sketches

Show the solution's shape through load-bearing types, signatures, handlers, endpoints, and contracts. These sketches are normative but amendable: implementation should follow them unless it reveals a problem, in which case the plan must be revised first.

- Write signatures and types, never implementation bodies. Use `// ...`, `TODO`, or an equivalent placeholder.
- Sketch only public boundaries, core data models, contracts shared across phases, and details that are easy to misunderstand.
- Use about 30 to 80 lines in total. Skip code for small tasks when no interface sketch adds value.
- Use the repository's language. If the language is genuinely ambiguous, default to Go.
- Choose the simplest shape that satisfies the acceptance criteria.
- Do not add speculative abstractions, plugin systems, generic extension points, or interfaces with one implementation.

## 7. Project acceptance criteria

Recommend one to ten criteria based on the goals and repository. Prefer a runnable command followed by its exact expected result:

```text
AC-1: `npm test -- auth.test.ts` -> exit 0; the suite covers login, logout, and expired tokens
AC-2: `curl -s -o /dev/null -w "%{http_code}" localhost:3000/dashboard` without a cookie -> `302`
AC-3: `npm run build` -> exit 0 with no new type errors
```

Every criterion must be independently checkable by the orchestrator from the terminal. Inspect the repository to identify appropriate commands. If no test exists, require the relevant phase to create one. Use a manual check only when automation is impractical; state exact steps and the expected observation.

Reject subjective criteria such as "the code is clean," "performance is good," or "the UI feels smooth."

## 8. Phased plan

Recommend one to six phases. Each phase must be:

- Atomic: it leaves the repository working and committable.
- Core-first: it proves the project's essential claim before ancillary work.
- Data-model-first when applicable: define entities, fields, identifiers, relationships, constraints, ownership, lifecycle, indexes or query patterns, and migration/backfill/rollback needs before dependent behavior. Do not invent data-model work when no persisted or shared state changes.
- Risk-aware: move a blocking library or external API spike into the earliest sensible phase.
- Orchestrator-verifiable: it ends with commands and expected results.

Use core-first order unless the user explicitly requires another order. Ask about ordering only when viable sequences carry materially different risks.

In file mode, use this template inline for every phase:

```markdown
### Phase N: <name>
**Status:** [ ] NOT STARTED
<!-- [ ] NOT STARTED | [~] IN PROGRESS | [x] COMPLETE (date, verified by: <command and result>; code review: <result>) -->
**Outcome:** One sentence describing what this phase proves or delivers.
**Changes:**
- Deliverable
**Verification (orchestrator-owned):** Exact command(s), expected output, and expected exit code. Use a precise manual check only when no command is practical.
```

In GitHub mode, the parent issue's `## 8. Phased plan` section is an ordered list of phase issue links. Each managed sub-issue uses this body:

```markdown
<!-- phased-plan-phase:v1 -->
**Status:** [ ] NOT STARTED
<!-- [ ] NOT STARTED | [~] IN PROGRESS | [x] COMPLETE (date, verified by: <command and result>; code review: <result>) -->

## Outcome
One sentence describing what this phase proves or delivers.

## Changes
- Deliverable

## Verification (orchestrator-owned)
Exact command(s), expected output, and expected exit code.
```

Put `Depends on`, `Out of scope`, or `Est. size` in the phase only when it changes execution.

## 9. Open questions

Collect only blocking `[NEEDS CLARIFICATION]` items so the user can answer in one pass. Include no more than three. If none remain, write `None.`

# 5. Status protocol

- Every phase starts as `[ ] NOT STARTED`.
- Before delegation, the orchestrator gives each builder the entire current phase verbatim plus relevant goals, constraints, interfaces, acceptance criteria, assigned scope, exclusions, and repository state.
- Before coding, record `[~] IN PROGRESS` using the backend's protocol: the designated builder includes the file update in its first implementation commit, while the orchestrator edits a GitHub phase issue before delegation.
- Builders must not run tests, builds, linters, format checks, type checks, acceptance commands, or other verification. They may use LSP and must fix every diagnostic in changed code files.
- After builder work, the orchestrator runs the phase's exact verification once. If a command fails, the responsible builder fixes it and the orchestrator reruns only that failed command.
- After verification passes, the orchestrator runs one code review over the complete phase commit range. Builders fix all findings in one pass. Do not review or verify the phase again after those fixes; the final branch review is the backstop.
- The orchestrator marks a phase `[x] COMPLETE` only after verification passes and every review finding is fixed, accepted, or invalidated.
- A completion record includes the date, command and result, and phase-review outcome, for example: `[x] COMPLETE (2026-07-19, verified by: npm test -- store.test.ts -> 14 passed; code review: 2 findings fixed)`.
- A resuming orchestrator reads the entire selected plan artifact and continues from the earliest incomplete phase without re-verifying completed phases.

In file mode, the file is the source of truth and status updates follow the existing commit protocol used by `/phased-build`.

In GitHub mode, the issue hierarchy is the source of truth. The orchestrator edits the phase body for pending and active states, adds completion evidence as a comment, then records `[x] COMPLETE` and closes the phase issue. The parent remains open until all final gates pass.

# 6. GitHub persistence contract

Use compatible native `gh issue` commands and quoted stdin; do not create temporary files.

For a new hierarchy, create the parent before its managed phase sub-issues. The initial parent body must contain the complete spec with an ordered phase-title index; replace that index with issue links after creating the children.

```bash
title="<concise project title>"
parent_url="$(
  gh issue create --title "$title" --body-file - <<'EOF'
<!-- phased-plan:v1 -->
...
EOF
)"
parent="${parent_url##*/}"

gh issue create --title "Phase N: Name" --body-file - --parent "$parent" <<'EOF'
<!-- phased-plan-phase:v1 -->
...
EOF

gh issue edit "$parent" --body-file - <<'EOF'
<!-- phased-plan:v1 -->
...
EOF

gh issue edit "$phase" --body-file - <<'EOF'
<!-- phased-plan-phase:v1 -->
...
EOF
```

For a removed pending phase:

```bash
gh issue edit "$phase" --remove-parent
gh issue comment "$phase" --body-file - <<'EOF'
Removed from the phased plan because ...
EOF
gh issue close "$phase" --reason "not planned"
```

For reordered pending phases, obtain integer issue IDs with `gh api "repos/{owner}/{repo}/issues/$phase" --jq .id`, then call:

```bash
gh api --method PATCH \
  "repos/{owner}/{repo}/issues/$parent/sub_issues/priority" \
  -F sub_issue_id="$sub_issue_id" \
  -F after_id="$after_id"
```

Use `before_id` instead when moving before another phase. Do not call the ordering endpoint when titles changed but order did not.

In creation mode, create the parent, create each managed phase issue sequentially, then edit the parent body with the final ordered links. In revision mode, create or update managed phase issues sequentially before editing the parent. If an operation fails partway through, do not delete or duplicate successful issues. Report the parent and completed child URLs, then instruct a retry against the same parent issue.

# 7. Right-sizing and anti-patterns

- Small task, one file or less than about one day: use one or two phases. Write `Not needed for this task.` under Architecture Sketch or Interface Sketches when appropriate.
- Medium feature, about one week: use the full template.
- Large, multi-week or multi-system project: keep the parent concise and split phases rather than adding prose.
- Keep the shared spec within roughly one to three screens. Keep each phase self-contained but compact.
- Do not dictate variable names, internal file layout, or choices an implementation agent can safely make.
- Do not omit Non-Goals, use subjective acceptance criteria, hide assumptions, defer dependent data-model work, or create a "build everything, then test everything" sequence.
- Do not change code before creating or amending the selected plan artifact.
- Do not mark a phase complete before exact verification and its single phase review finish.
- Do not alter completed phases or the scope/order of active phases; add pending follow-up work instead.

# 8. Persist and report

After blocking questions are resolved:

- New file mode: create the fresh collision-safe path selected under target resolution.
- Explicit file target: create or revise exactly that path. Do not create a second plan file.
- New GitHub mode: create a fresh parent with `<!-- phased-plan:v1 -->`, then create and link every managed phase sub-issue.
- Existing GitHub target: add or preserve `<!-- phased-plan:v1 -->`, reconcile only managed phase sub-issues, and preserve unrelated sub-issues and the parent title.
- If no blocking questions remain, persist immediately without asking for approval.
- Do not implement the project or hand it to an implementation agent as part of this command.
- Report the file path or parent issue URL, the ordered phases, every managed phase issue URL in GitHub mode, and any locked-phase request converted to follow-up work.
