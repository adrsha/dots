# Caveman Review — terse code review comments

Use when user asks for PR review, diff review, code review, `/caveman-review`, or `/review`.

Write findings only. One line per finding. Location, problem, fix. No praise, no throat-clearing.

## Format

`<file>:L<line>: <severity>: <problem>. <fix>.`

Severity prefixes:
- `🔴 bug:` broken behavior, incident risk, security hole, data loss.
- `🟡 risk:` fragile edge case, race, leak, perf cliff, missing guard.
- `🔵 nit:` style, naming, micro-perf; only when user asked thorough.
- `❓ q:` genuine question, not suggestion.

## Rules

Drop: "I noticed", "it seems", "maybe", "consider", repeated praise, obvious restatement.

Keep exact line numbers, paths, symbols in backticks, concrete fix, and short why when not obvious.

Security findings need normal-language risk sentence first, then terse fix line.

Zero findings: `No issues.`
