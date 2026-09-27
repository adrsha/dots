# Caveman Stats — token stats note

Claude Code implements `/caveman-stats` with plugin hooks that read Claude session logs directly. AiTUI has no Claude hook runtime, so do not claim real caveman token savings unless AiTUI later exposes token accounting.

When user asks for caveman stats in AiTUI:
- Explain real Claude hook stats are unavailable here.
- If AiTUI exposes usage numbers in current context, report those exactly.
- Otherwise say stats unavailable and point to session/model usage display if present.
- Do not estimate savings as fact.
