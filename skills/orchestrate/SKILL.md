---
name: orchestrate
description: Implement the plan in the current context, then hand off to context-free code-review and security-review subagents (security review always runs unless explicitly declined). Use whenever the user asks to orchestrate, for build-with-review, "build then review", or wants implementation followed by an independent review. Use only when the user explicitly asks for it.
argument-hint: "[model[#effort]] [review scope]"
---

# orchestrate

Implement the plan already agreed in this context, then get it reviewed by
subagents that know nothing about this conversation. The reviewers must judge
the code on their own; passing plan summaries or rationale would bias the
review.

## Arguments

The first argument, if present, is the reviewer model, optionally followed by
an effort word (low, medium, high, xhigh, max) or written as
`provider/model#variant`. Examples: `opus high`, `astra medium`,
`openai/gpt-6.1-sol#low`. Everything after it is the review scope. The same
model and effort apply to both reviewers.

If no model is specified, use the harness default:

- Codex: `openai/gpt-6-astra#high` (Astra, high effort)
- Claude Code: `anthropic/claude-opus-5-5#high` (Opus, high effort)
- OpenCode: `openai/gpt-6-astra#high` (Astra, high effort)
- Unknown harness: ask the user which model and effort to use before
  spawning the reviewers.

## Questions first

Batch every question into one round before any orchestration starts, so the
rest of the run proceeds without interruptions. Before implementing, resolve
all of the following:

- **No plan in context:** ask for one.
- **Unknown harness:** ask for the reviewer model and effort.
- **Verification scope:** discover the repo's full verification commands and
  test tiers up front (see the Verify section). If what to run is ambiguous —
  no discoverable suite, or an unclear E2E tier — settle it with the user
  now, not mid-run.

If something genuinely unforeseen appears later, decide from the repo's own
conventions and the defaults in this skill, and note the call in the report.
The one exception is Critical findings, which always go to the user at the
end — that is part of the final report, not a mid-run interruption.

## Implement

1. If there is no plan in the current context, ask for one. Do not invent work.
2. Record the current HEAD SHA: `git rev-parse HEAD`. The reviewers will use
   it to find what changed.
3. Implement the plan. No re-planning, no scope creep. Run focused checks as
   you go and commit the work the way the repo expects.

## Review

When implementation is done, spawn two subagents in the same turn so they run
in parallel: one invokes the `code-review` skill, the other invokes the
`security-review` skill. Both get the same scope: `changes since <HEAD SHA>`
plus any user-supplied scope.

Each subagent prompt contains nothing but:

- An instruction to invoke its skill (`code-review` or `security-review`).
- The scope and the repository path.
- The model and effort directive, in the form the harness supports. On
  OpenCode, set the subagent tool's `model` parameter to the
  `provider/model#variant` id and keep the directive out of the prompt. On
  Claude Code and Codex, state the model and effort in the prompt.

Pass no conversation history, no plan summary, no list of changes, and no
apology or rationale. The subagents start with fresh sessions anyway; the
point is that your prompts must not become a channel for context. Do not act
on, answer, or annotate anything on the reviewers' behalf.

Run one review round. Do not re-run the reviewers after fixing — the full
verification step below is what catches regressions.

## Fix

Merge the two reports and drop findings that share a root cause. Confirm each
finding in the code before you act on it.

- **Critical (`C*`, `SEC-C*`) or a fix that needs a major re-architecture or
  refactor:** do not fix. Save it for the report. Critical findings always
  need the user's decision — never fix them on your own initiative.
- **High, Medium, and Low:** fix it with the recommended solution.
- **Invalid:** skip it and note why.
- **Questions:** answer from the code, or save them for the report.

Commit each fix atomically: one root cause, with its tests, after its focused
checks pass. Stage paths by name and follow the repo's commit style. Never
amend, skip hooks, force, or push. If a file had uncommitted changes before
the run, leave its fix uncommitted.

After all fixes, run focused checks over everything you changed. Fix and
commit any failure that you caused.

## Report

Surface both reviewers' findings, with duplicates merged. List: Critical and
refactor findings with their possible solutions and your recommendation,
fixes with their commit SHAs, uncommitted fixes, skipped findings, open
questions, and check results.

Then ask the user how to handle each Critical and refactor finding. Run
focused checks on each chosen fix, then commit it the same way.

## Verify

Once all fixing is complete — the automatic non-Critical fixes and any
user-chosen Critical or refactor fixes — run the repo's full verification
suite yourself. Focused checks are not enough: they only cover the code the
run touched, while the point here is to catch breakage elsewhere.

Full verification means every piece of static analysis and linting the repo
has, plus all of its tests passing. Discover what that means for this repo
instead of assuming: a Makefile's default or obvious targets, `package.json`
scripts like `test`, `lint`, `typecheck`, and `build`, pytest or other
project-level suites, and the steps the repo's CI runs.

Test tiers are a judgment call, and slow end-to-end suites are the usual
trap. Run the unit and integration tiers by default; run a full E2E suite
only when the repo's own instructions — its Makefile, docs, or CI
configuration — treat E2E as part of standard verification, not just a
nightly or release job. Any ambiguity about what to run was settled in the
Questions-first round; follow what was agreed there.

Fix and commit any failure the run's changes caused, with the same commit
discipline as the Fix section. Fix pre-existing failures too, as separate
commits so their root causes stay distinct, and say in the report which
failures predated the run.

Report the verification results: which commands ran, whether they passed,
which failures came from the run's changes versus predated it, and how each
was fixed.
