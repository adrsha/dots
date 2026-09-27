# Cavecrew — compact delegation patterns for AiTUI

Claude cavecrew uses subagents. AiTUI has no Claude subagent runtime, so apply these patterns in main thread with AiTUI tools and terse receipts.

## Investigator pattern

Use for: "where is X", "what calls Y", "list uses", "map directory".

Workflow: search first, read only relevant ranges, report paths first. Do not edit.

Output:
```
Defs:
- path:line — `symbol` — short note
Refs:
- path:line — `symbol` — short note
totals: N defs, M refs.
```
Zero hits: `No match.`

## Builder pattern

Use for obvious surgical edits in 1-2 files. Read before edit. Smallest diff. Re-read or test after edit. No drive-by refactor.

Receipt:
```
path:line-range — change ≤10 words.
verified: re-read OK | test OK | mismatch @ path:line.
```
If 3+ files/new feature/ambiguous/destructive: ask or keep in main plan; do not pretend bounded builder can do it.

## Reviewer pattern

Use for diff/file review. Findings only, sorted file then line.

```
path:line: 🔴 bug: problem. fix.
path:line: 🟡 risk: problem. fix.
totals: 1🔴 1🟡
```
Zero findings: `No issues.`

## Rule

If output will be injected back into main context, compress it. If human needs rationale, expand only that piece.
