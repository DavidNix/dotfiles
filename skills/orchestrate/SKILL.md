---
name: orchestrate
description: Implement the plan in the current context, then hand off to a context-free code-review-fix subagent (security review always on unless explicitly declined). Use whenever the user asks to orchestrate, for build-with-review, "build then review", or wants implementation followed by an independent review. Use only when the user explicitly asks for it.
argument-hint: "[model[#effort]] [review scope]"
---

# orchestrate

Implement the plan already agreed in this context, then get it reviewed by a
subagent that knows nothing about this conversation. The reviewer must judge
the code on its own; passing plan summaries or rationale would bias the review.

## Arguments

The first argument, if present, is the reviewer model, optionally followed by
an effort word (low, medium, high, xhigh, max) or written as
`provider/model#variant`. Examples: `opus high`, `astra medium`,
`openai/gpt-6-astra#high`. Everything after it is the review scope.

If no model is specified, use the harness default:

- Codex: `openai/gpt-6-astra#high` (Astra, high effort)
- Claude Code: `anthropic/claude-opus-5-5#high` (Opus, high effort)
- OpenCode: `openai/gpt-6-astra#high` (Astra, high effort)
- Unknown harness: ask the user which model and effort to use before
  spawning the reviewer.

## Implement

1. If there is no plan in the current context, ask for one. Do not invent work.
2. Record the current HEAD SHA: `git rev-parse HEAD`. The reviewer will use it
   to find what changed.
3. Implement the plan. No re-planning, no scope creep. Run focused checks as
   you go and commit the work the way the repo expects.

## Review

When implementation is done, spawn a subagent and pass it nothing but this:

- An instruction to invoke the `code-review-fix` skill.
- The scope: `changes since <HEAD SHA>` plus any user-supplied scope.
- The model and effort directive, in the form the harness supports. On
  OpenCode, set the subagent tool's `model` parameter to the
  `provider/model#variant` id and keep the directive out of the prompt. On
  Claude Code and Codex, state the model and effort in the prompt.

Pass no conversation history, no plan summary, no list of changes, and no
apology or rationale. The subagent starts with a fresh session anyway; the
point is that your prompt must not become a channel for context. Do not act
on, answer, or annotate anything on the reviewer's behalf.

## Report

When the reviewer finishes, surface its report to the user as-is, including
any Critical findings and open questions. Do not fix the findings yourself —
the reviewer already committed its fixes; what reaches you is what it could
not or should not act on alone. Stop after surfacing it unless the user asks
for more.
