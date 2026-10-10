## Goal
Fix notification stacking and unwanted focus; use end4-pC source-informed visual system across current shell, retaining bar-free layout and existing capabilities. Research saved in `DESIGN_RESEARCH.md`.

## Proposed sequence
1. Audit live Quickshell popup/focus behavior and screenshot current launcher, center, wallpaper studio on actual display; confirm Unsplash credential *presence* in shell process environment without printing value.
2. Replace singleton popup/timer with bounded per-entry stack; preserve notification history, actions, inline replies and DND. Request no keyboard focus on passive arrival; permit deliberate reply interaction only. Test multi-arrival, hover, close, focus and overflow.
3. Establish theme-mapped role tokens, typography/spacing/radius ladder from research. Restyle popup and notification center first; inspect screen captures and iterate.
4. Carry same hierarchy to launcher, dashboard, wallpaper studio and control panels while preserving opaque surfaces and bar-free desktop; address low-resolution layout and light/dark legibility.
5. Run `qmllint`, Python tests, IPC and targeted visual/focus tests; update README with behavior and any unverified manual checks.

## Constraints / assumptions
- Inspiration, not copy: preserve theme-manager palette, existing structure/features and no persistent bar.
- Unsplash key already provisioned; do not store, log or hardcode token. If process environment lacks it, identify precise environment inheritance fix before changing credential setup.
- Existing notification server retains DBus ownership; no compositor reload, service replacement or lock invocation.

## Risks
- Layer-shell focus/mask interaction differs by compositor; focus must be verified with a real focused application. Inline reply may require a separate explicitly focused surface if passive layer cannot accept text reliably.
- Large UI restyle benefits from visual review after notification behavior is corrected; report separates observed upstream facts from proposed local design choices.