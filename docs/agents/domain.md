# Domain docs

## Before exploring

Read root `CONTEXT.md` for project vocabulary.
Read relevant decisions under `docs/adr/` before changing the behavior they cover.
If these documents do not exist, proceed silently.

## Layout

This repository uses a single context:
- `CONTEXT.md`: domain glossary.
- `docs/adr/`: architectural decisions, created only when a decision warrants an ADR.

Keep product scope in `README.md`; keep implementation details out of the glossary.
The `domain-modeling` skill maintains vocabulary and creates ADRs as decisions are resolved.

## Consumer rules

Use glossary terms consistently in issues, proposals, code, and tests.
Note meaningful vocabulary gaps for `domain-modeling`.
Surface conflicts with existing ADRs explicitly before proposing a replacement.
