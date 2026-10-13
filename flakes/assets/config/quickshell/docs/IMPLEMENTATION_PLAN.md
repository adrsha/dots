## Goal
Build one bar-free Quickshell for Hyprland: on-demand launcher, command center, wallpaper browser, dashboard, notification center, media/lyrics, lock surface, and focused-window affordance. No persistent top/bottom bar.

## Existing setup
`~/.config/quickshell` empty. Hyprland already starts `qs -d` and binds several `qs ipc call shell ...` commands, but local shell does not implement them. Both `hyprland.conf` and `hyprland.lua` exist; Lua binds launcher/lock differently. `qs`/`quickshell` not on current PATH, so live UI validation may require installing or locating executable. Existing `swaync`, Vicinae, `awww`, NetworkManager, BlueZ, and playerctl may overlap.

## Build sequence
1. Establish actual active Hyprland configuration, Quickshell executable/version, available Qt modules, lock and lyrics providers. Inventory existing wallpapers and theme integration; avoid touching system-wide settings.
2. Implement small shell core: theme tokens, shared state/services, IPC router matching existing bindings, reusable cards/buttons, modal/window behavior, keyboard navigation. Keep everything hidden until invoked.
3. Deliver functional slices: launcher + dashboard; Wi-Fi/Bluetooth/audio/brightness/DND + notifications; wallpaper library/search/apply; media controls + lyrics; lock/power; active-window indication; workspace and application in workspace display while holding meta key. Implement each with error/empty states and explicit dependencies.
4. Integrate Hyprland shortcuts/startup only after verified. Replace conflicting external services incrementally, never turn off working launcher/notifications/lock before equivalent works.
5. Validate QML startup, IPC actions, focus/escape handling, multi-monitor behavior, offline/dependency failure, and whether desktop remains bar-free. Document setup and keybindings.

## Design direction
Original interface inspired by end-4 and end4-pC: spacious layered cards, restrained motion, wallpaper-driven colors, strong typography, fast search. Inspiration only; avoid copying source/assets wholesale. Default to local `~/Pictures/walls`, `awww` for applying, and existing Hyprland color/theme pipeline.

## Risks / decisions
Lock is security-critical: use established lock program, never fake lock with a dismissible Quickshell overlay. Network credentials need NetworkManager-owned prompt/secret agent. Online wallpaper discovery needs chosen source/license and download policy. Full feature set spans several tested increments, not one unverified monolith.
User agrees with lock being security critical and prefers it to be more of a screensaver in concept but with password entry and other lock screen system.
