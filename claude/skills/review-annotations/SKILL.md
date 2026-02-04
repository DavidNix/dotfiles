---
name: review-annotations
description: "Process ATODO (Agent TODO) comments from code review. Finds comments like `// ATODO: refactor this` or `# ATODO: add error handling`, executes the instructions, and removes the comments."
---

Find and execute ATODO comments left during code review, then remove them.

## Comment Syntax

| Language | Syntax |
|----------|--------|
| JS/TS/Go/Rust/Java/C/C++ | `// ATODO: ...` |
| Python/Ruby/Shell/YAML | `# ATODO: ...` |
| HTML/XML | `<!-- ATODO: ... -->` |
| CSS | `/* ATODO: ... */` |

## Workflow

### Step 1: Find Changed Files

```bash
git diff --name-only
```

If no uncommitted changes, also check staged:
```bash
git diff --cached --name-only
```

### Step 2: Search for ATODOs

Use Grep to find all ATODO comments in the changed files:

```
pattern: ATODO:
path: <each changed file>
output_mode: content
```

### Step 3: Display Summary

Show all found ATODOs in a table:

| File | Line | Instruction |
|------|------|-------------|
| src/utils.ts | 42 | refactor to use async/await |
| lib/api.py | 15 | add input validation |

### Step 4: Confirm with User

Ask user to confirm before proceeding:
- "Found N ATODO comments. Proceed with executing all?"
- Options: Yes (execute all), No (abort)

### Step 5: Execute Each ATODO

For each ATODO:
1. Read the file context around the comment
2. Execute the instruction (refactor, add code, fix issue, etc.)
3. Delete the ATODO comment line entirely
4. Verify the change is correct

### Step 6: Report Completion

Summarize what was done:
- Number of ATODOs processed
- Brief description of each change
- Any issues encountered

## Important Notes

- Only search files with uncommitted changes (not the entire codebase)
- Execute instructions in the order they appear
- If an instruction is unclear, ask for clarification before proceeding
- Always delete the ATODO comment after executing its instruction
