---
name: code-review
description: "Launch parallel code reviews using claude-reviewer (Opus) and other models. Only invoke when the user explicitly requests code review."
disable-model-invocation: true
argument-hint: [uncommitted]
---

Launch both reviewers in parallel for comprehensive code review.

## Usage

```
/code-review [uncommitted]
```

- No args: Review committed changes against upstream (origin/main or origin/master)
- `uncommitted`: Review uncommitted/staged changes

## Execution

Run in parallel:

1. **claude-reviewer** (Task tool, subagent_type: `claude-reviewer`)
   - Pass `$ARGUMENTS` verbatim

<!--2. **codex-reviewer** (Task tool, subagent_type: `codex-reviewer`)
   - Pass `$ARGUMENTS` verbatim-->

## Output

If more than one agent, combine findings from both reviewers into a single unified table grouped by severity. Include a "Reviewer" column showing which reviewer(s) found each issue. If both reviewers found the same or similar issue, e.g. "Claude, Codex" in the Reviewer column.

Example format:
```
## High Severity
┌────────────────────────────┬──────────────────┬───────────────────────────────────────────────────────────┬───────────────┐
│           Issue            │     Location     │                        Description                        │   Reviewer    │
├────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┼───────────────┤
│ Missing CSRF protection    │ login.go:102     │ Callback should validate OAuth state parameter.           │ Codex         │
├────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┼───────────────┤
│ Hardcoded callback port    │ login.go:329     │ Port 8085 hardcoded with no fallback.                     │ Claude, Codex │
└────────────────────────────┴──────────────────┴───────────────────────────────────────────────────────────┴───────────────┘

## Medium Severity
...
```

If both find no issues, state the code looks solid.
