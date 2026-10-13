# Quickshell UI configuration

Edit `shell-settings.json` in this directory. Changes are watched automatically.

```json
{
  "normalModeKey": "jk",
  "jkTimeoutMs": 250
}
```

- `normalModeKey`: `escape` (default) or `jk`.
- In `jk` mode, press lowercase **j**, then **k** within the timeout while editing
  a StudioField (including launcher and wallpaper searches). The chord removes
  the inserted j, consumes k, and leaves input focus for normal-mode navigation.
  It does not close the panel. Press **i** to return to the panel's search field.
- Slow `jk`, modified keys, and sequences containing another key remain ordinary
  text. Escape remains available as a safety fallback in either mode.
- `jkTimeoutMs`: 80–1000 ms; default 250 ms.

Outer glass opacity continues to follow the active theme's `opacity` value
(`0.2` means 20% opaque). Local result/workspace cards use a minimum 88% backing
opacity for readability, as do header and keyboard-hint backings; text and
themed icon tiles stay opaque.

The app icon component uses desaturated theme-tinted desktop artwork on rounded
accent tiles, inspired by `~/Codes/Launcher`'s two-tone rendering. Desktop icons
lack Android's adaptive monochrome layers, so this is not its exact pixel-mask
renderer. Unavailable artwork has a bundled fallback.

Checks:

```sh
qmllint shell.qml ui/components/*.qml ui/desktop/WorkspaceOsd.qml ui/panels/*.qml
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests/qml
PYTHONPATH=services python3 -m unittest discover -s tests -q
```
