---
description: Orchestrate builds with atomic commits and final code and security reviews
subagent: false
---

Orchestrate to completion: $ARGUMENTS

## Scope

- Use the arguments, or the current request if omitted. Read referenced files/issues; use `gh-issues` for GitHub input.
- Read repository instructions. Establish scope, acceptance criteria, design decisions, verification commands, starting SHA, and dirty-path baseline. Preserve unrelated work; ask before touching conflicting dirty paths.
- Inherit the session's model/reasoning settings and each subagent's configured defaults.

## Implement and delegate

- Decide whether to implement directly or delegate to `builder`, or `frontend-builder` for frontend work. Delegation is advisable for narrowly scoped, independently verifiable tasks. You own planning, coordination, evidence, and reviews.
- Split work into independently verifiable outcomes with explicit dependencies and path ownership. No fixed phases or todo tool.
- Keep a compact conversation ledger: unit, dependencies, owner/paths, status, `sessionID` when delegated, commits/checks, and unresolved findings. Update at milestones; include next actions when pausing. Persist elsewhere only when requested.
- Actively look for opportunities to run independent builders in parallel. Choose serial execution when dependencies, shared writes, generated files, or checks could conflict. Use `background: true` and completion notifications, not polling. Resume builders by `sessionID` for related fixes; start fresh sessions for unrelated work.
- Run checks on stable inputs. For parallel work in a shared worktree, wait until writers finish, then make commits one at a time. Integrate isolated-worktree changes directly or delegate integration to a builder.
- Give each builder requirements, resolved design, scope/exclusions, owned paths, baseline/current SHA, intervening changes, exact checks, and commit instructions. Require changed paths, check results, commit SHA, and blockers before marking complete.
- Require `ai-tdd` for testable application changes; use relevant validation for documentation, configuration, infrastructure, and wiring. Whoever implements owns focused checks. Always make atomic commits: one verified, coherent change per commit, including fixes. These requirements apply to both direct and delegated work. Preserve honest test chronology.
- Never stage unrelated changes, amend, skip hooks, force Git operations, or push without permission.

## Review and fix

- Choose intermediate `code-review` checkpoints as useful. Reviewers report; implement fixes directly or delegate them.
- For both code and security findings: pause implementation and dispatch before Critical fixes and ask for approval. Automatically resolve actionable High, Medium, and Low findings. Investigate questions; ask when evidence cannot resolve a necessary decision safely.
- Treat major architecture, irreversible contract, or scope changes as Critical decisions. Fix blockers promptly; group other findings by root cause for hardening before completion.

## Required final gate

1. Finish integration and confirm focused-check evidence for all direct and delegated work.
2. Always dispatch final `code-review` and `security-review` agents concurrently against the same pinned SHA, covering this run's changes. Supply requirements, scope, prior findings, and verification evidence; require their respective skills. Intermediate reviews never replace these.
3. Keep the tree stable until both return. Apply the finding policy above and implement fixes directly or delegate them. Verify affected behavior; request targeted re-review as needed, repeating affected final reviews after material architecture, security, or integration changes.
4. After reviews and fixes, run full applicable verification yourself against the final tree. Fix failures directly or delegate them, then rerun full verification after fixes so the final run covers the delivered tree.
5. Finish only when final full verification passes, both reviews complete, and findings are verified fixed, explicitly accepted, or confirmed invalid. Report missing checks/reviewers as blockers, never success.

Summarize delivery, verification, both final reviews, and remaining risks or blockers. Preserve referenced files and issues unless changes were requested.
