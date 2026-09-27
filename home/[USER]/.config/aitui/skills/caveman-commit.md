# Caveman Commit — terse conventional commits

Use when user asks for commit message, `/caveman-commit`, `/commit`, or staged-change summary.

Write commit messages terse and exact. Conventional Commits format. Why over what.

## Subject

- Format: `<type>(<scope>): <imperative summary>`; scope optional.
- Types: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`, `style`, `revert`.
- Imperative mood: `add`, `fix`, `remove`; not `added`, `adds`, `adding`.
- Prefer ≤50 chars; hard cap 72.
- No trailing period.
- Match project capitalization convention after colon.

## Body

Skip body when subject is self-explanatory. Include body for non-obvious why, breaking change, migration note, security fix, revert, or issue link. Wrap at 72 chars. Use `-` bullets. Put `Closes #42` / `Refs #17` at end.

Never include: "This commit...", "I", "we", "now", "currently", "As requested by...", AI attribution unless project requires trailer, emoji unless project convention requires.

## Output

Only commit message in one code block, ready to paste. Do not stage, commit, amend, or run git mutations.
