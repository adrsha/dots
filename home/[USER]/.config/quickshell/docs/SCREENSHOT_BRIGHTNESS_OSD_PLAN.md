## Existing bindings
- `Print` → `toggleScreenshot` (currently missing): screenshot chooser.
- `Super+Print` → `screenshot window save`; `Shift+Print` → `screenshot output save`; `Ctrl+Print` → `screenshot region lens` (all missing).
- Brightness keys call missing `changeBrightness`; current `XF86MonBrightnessDown` passes `+5`, Up passes `-5`—directions reversed.
- `shell.qml` has controls and volume IPC but no OSD. `backend.py` has volume action, no screenshot/brightness implementation.

## Proposed sequence
1. Implement safe screenshot backend (`grim`/`slurp` and Hyprland geometry) with validated `region|window|output` and `save|clipboard|lens` modes, atomic file naming under `~/Pictures/Screenshots`, cancellation without false success, and explicit missing-tool errors. Provide Print chooser matching established panel style; preserve existing binds where meanings are clear.
2. Add monitor brightness service using `ddcutil`: detect controllable displays, read VCP 0x10, clamp 0–100%, map keyboard increments, serialize/coalesce repeated requests to avoid DDC contention, report unavailable displays without misreporting success. Decide multi-monitor behavior and laptop fallback before implementation.
3. Add compact, timed, non-focus-stealing volume/brightness/screenshot OSD with progress and success/failure states; integrate IPC and controls UI, and correct reversed brightness bindings after verification.
4. Add unit tests with mocked commands; run `qmllint`, Python tests, live IPC checks, and inspect real display captures/OSD where tools exist. Do not replace existing compositor bindings or change hardware brightness until validation.

## Risks and assumptions
`lens` meaning unknown; screenshot utility availability unresolved from tool command lookup; DDC operations affect hardware and may be slow. “Everything else” could mean remaining README features (lyrics, Bluetooth pairing, Wi-Fi browser, power confirmation, workspace overview), which would be separate feature slices rather than bundled implicitly.
User: Lens means google lens. Find its api, test if its working, and implement the ability to search images that are taken screenshot of directly.
