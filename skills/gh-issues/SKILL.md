---
name: gh-issues
description: Use when creating, listing, viewing, editing, commenting on, closing, reopening, or organizing GitHub issues and sub-issues with the gh CLI
---

# GitHub issues with gh

Manage issues and native parent/sub-issue relationships with the installed `gh` CLI.

## Interaction rules

- If the user or calling command already supplies the action and target, proceed without asking them to choose an action again.
- Infer a bare issue number or `#<number>` as an issue in the current repository and an issue URL as its explicit repository. Strip the leading `#` before passing a number to `gh`.
- Ask only when required information is missing or the target, repository, or requested mutation is genuinely ambiguous.
- Before mutating an issue from another repository, confirm that the repository is intentional.
- Never expose authentication tokens or read GitHub credential files.

## Preflight

For mutations, verify authentication and repository access before changing anything:

```bash
gh auth status
gh repo view --json nameWithOwner,hasIssuesEnabled,viewerPermission,url
```

Require issues to be enabled and `WRITE`, `MAINTAIN`, or `ADMIN` permission. For sub-issue work, confirm that the installed CLI exposes `--parent` and `--add-sub-issue` if compatibility is uncertain:

```bash
gh issue create --help
gh issue edit --help
```

If those flags are absent, report that the installed `gh` must be upgraded. Do not silently replace native sub-issue relationships with task-list links.

## Multiline bodies

Pass Markdown through quoted stdin so formatting is preserved, shell expansion is disabled, and no temporary file is created:

```bash
gh issue create --title "Issue title" --body-file - <<'EOF'
## Description

Issue body.
EOF
```

Use the same `--body-file -` pattern with `gh issue edit` and `gh issue comment`.

## Compatible commands

| Action | Command |
|---|---|
| List | `gh issue list --state all --json number,title,state,parent,url` |
| View | `gh issue view "$issue" --json number,title,body,state,stateReason,parent,subIssues,subIssuesSummary,comments,url` |
| Create | `gh issue create --title "$title" --body-file -` |
| Create sub-issue | `gh issue create --title "$title" --body-file - --parent "$parent"` |
| Edit body | `gh issue edit "$issue" --body-file -` |
| Add existing sub-issue | `gh issue edit "$parent" --add-sub-issue "$child"` |
| Set parent | `gh issue edit "$child" --parent "$parent"` |
| Remove parent | `gh issue edit "$child" --remove-parent` |
| Remove sub-issue | `gh issue edit "$parent" --remove-sub-issue "$child"` |
| Comment | `gh issue comment "$issue" --body-file -` |
| Close completed | `gh issue close "$issue" --reason completed` |
| Close canceled | `gh issue close "$issue" --reason "not planned"` |
| Reopen | `gh issue reopen "$issue"` |

Issue bodies are replaced as a whole. Read the current body first and preserve content the requested change does not supersede.

## Sub-issue ordering

GitHub supports up to 100 direct sub-issues per parent and eight nested levels. Native `gh issue` commands create and manage relationships, but they do not currently expose reprioritization. Use the REST endpoint through `gh api` only when order must change.

Get each issue's integer database ID, not its GraphQL node ID:

```bash
sub_issue_id=$(gh api "repos/{owner}/{repo}/issues/$child" --jq .id)
after_id=$(gh api "repos/{owner}/{repo}/issues/$previous_child" --jq .id)
gh api --method PATCH \
  "repos/{owner}/{repo}/issues/$parent/sub_issues/priority" \
  -F sub_issue_id="$sub_issue_id" \
  -F after_id="$after_id"
```

Use `before_id` instead of `after_id` when moving an issue before another child. Supply exactly one positional field.

## Hierarchy workflow

1. Read the parent and its `subIssues` before making changes.
2. Draft every issue body before the first creation to reduce partial hierarchies.
3. Create new children sequentially with `--parent` so their initial order is deterministic.
4. Update only recognized children. Ask before treating unrelated existing sub-issues as managed work.
5. Record durable execution evidence in comments before closing an issue.
6. Close children before their parent so GitHub's progress summary remains meaningful.
7. If a multi-issue operation fails partway through, preserve the successful issues, report their URLs, and resume against them. Do not delete or duplicate them automatically.

## Error handling

- Authentication failure: run `gh auth status` and report the failing host.
- Permission failure: report `viewerPermission`; do not request broader scopes unless the failed operation requires them.
- Missing issue or repository: verify the number, URL, current repository, and remote.
- Unsupported flag: report the installed `gh` version and required native flag.
- Validation or relationship error: check repository ownership, existing parent, nesting depth, and sub-issue count.
- Rate limit: stop and report the completed operations rather than retrying a mutation loop aggressively.
