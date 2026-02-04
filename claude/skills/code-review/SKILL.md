---
name: code-review
description: "Launch parallel code reviews using both claude-reviewer (Opus) and codex-reviewer (Codex CLI) agents. Only invoke when the user explicitly requests code review."
disable-model-invocation: true
---

Launch both reviewer agents in parallel for comprehensive code review.

## Usage

```
/code-review [PR#] [uncommitted]
```

- No args: Review committed changes against upstream (origin/main or origin/master)
- `PR#` or URL: Review a specific pull request
- `uncommitted`: Include uncommitted/staged changes

## Execution

Launch both agents in parallel using the Task tool:

1. **claude-reviewer** (subagent_type: `claude-reviewer`)
   - Uses Opus model
   - Reads code directly with Glob/Grep/Read tools

2. **codex-reviewer** (subagent_type: `codex-reviewer`)
   - Uses Codex CLI with gpt-5.2-codex
   - Extended reasoning (xhigh)

Pass `$ARGUMENTS` to both agents verbatim.

## Output

Present results under clear headers:

```
## Claude Review (Opus)
[claude-reviewer output]

## Codex Review
[codex-reviewer output]
```

If both find no issues, state the code looks solid.
