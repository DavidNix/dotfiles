---
name: code-review
description: "Launch parallel code reviews using claude-reviewer (Opus) and codex exec review. Only invoke when the user explicitly requests code review."
disable-model-invocation: true
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

2. **codex-reviewer** (Task tool, subagent_type: `codex-reviewer`)
   - Pass `$ARGUMENTS` verbatim

## Output

Present results under clear headers:

```
## Claude Review (Opus)
[claude-reviewer output]

## Codex Review
[codex output]
```

If both find no issues, state the code looks solid.
