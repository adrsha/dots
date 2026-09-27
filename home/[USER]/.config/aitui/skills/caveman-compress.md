# Caveman Compress — compress memory docs safely

Use when user asks `/caveman-compress <file>` or asks to compress a memory/prose file.

Compress natural-language files into terse caveman style while preserving technical substance.

## Allowed files

Only compress prose-like files: `.md`, `.txt`, `.typ`, `.typst`, `.tex`, extensionless prose. Never compress `.py`, `.js`, `.ts`, `.json`, `.yaml`, `.yml`, `.toml`, `.env`, `.lock`, `.css`, `.html`, `.xml`, `.sql`, `.sh`, or `*.original.md`.

Before overwriting, copy original to `<filename>.original.md` unless that backup already exists and user has not approved replacing it.

## Preserve exactly

- Fenced and indented code blocks.
- Inline code.
- URLs and markdown links.
- File paths, commands, environment variables.
- Technical terms, proper nouns, dates, version numbers.
- Markdown heading text, list nesting, table structure, frontmatter.

## Compress prose

Remove articles, filler, pleasantries, hedging, redundant phrasing, connective fluff. Use short synonyms. Fragments OK. Merge redundant bullets. Keep one example when many show same pattern.

If unsure whether text is code or prose, leave unchanged.
