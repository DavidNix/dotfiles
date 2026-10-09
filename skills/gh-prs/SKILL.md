---
name: gh-prs
description: Write short, why-first GitHub pull request titles and descriptions. Use when drafting, creating, or editing a GitHub PR or rewriting its title or body with the gh CLI.
---

# GitHub PRs

Reviewers need to know why a change matters. Make that reason clear right away.

- Read the repo instructions and the PR template that applies. Follow its required sections, order, prompts, and checklists, even when they override the rules below.
- Read the diff, any linked issue, and the current PR when editing. Use those facts to explain the reason for the work. Never invent a reason or claim checks passed without evidence.
- Start the body with one or two sentences about **why**: the problem, who it affects, or why it needs fixing. Never explain **what** changed: no change lists, file lists, or code walkthroughs, unless the template asks for them.
- Keep the body to two to four short bullets, with the opening reason in the first bullet. Use natural, 5th–6th grade language, short sentences, and common words. Keep the title short and clear. Skip jargon, filler, and extra headings unless the template needs them.
- For a draft, return the title and body. When asked to create or update the PR, use `gh pr create` or `gh pr edit`. Write the finished body to a temporary file and pass it with `--body-file` so Markdown stays intact.
