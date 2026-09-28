# Issue tracker: GitHub

Issues and specs live in GitHub Issues for `maytad/HandyBar`.
Use the `gh` CLI authenticated with your own account and the permissions needed
for the requested operation; verify the identity before writes.
The commands below use standard `gh`. RTK is an optional local wrapper.

## Conventions

- Create: `gh issue create --repo maytad/HandyBar --title "..." --body-file <file>`.
- Read: `gh issue view <number> --repo maytad/HandyBar --json number,title,body,labels,comments,state`.
- List: `gh issue list --repo maytad/HandyBar --state open --json number,title,body,labels,comments`; filter by label and state as needed.
- Comment: `gh issue comment <number> --repo maytad/HandyBar --body-file <file>`.
- Apply or remove labels: `gh issue edit <number> --repo maytad/HandyBar --add-label "..."` or `--remove-label "..."`.
- Close: `gh issue close <number> --repo maytad/HandyBar --comment "..."`.

Write multiline bodies to a UTF-8 file and pass it with `--body-file`.
Use the label mapping in `docs/agents/triage-labels.md`.

## Pull requests as a triage surface

**PRs as a request surface: no.**

GitHub shares issue and PR numbers. Resolve an ambiguous reference with
`gh pr view <number> --repo maytad/HandyBar`, then fall back to `gh issue view`.

## Skill operations

When a skill says "publish to the issue tracker", create a GitHub issue.
When a skill says "fetch the relevant ticket", read the issue, its labels, and comments.
