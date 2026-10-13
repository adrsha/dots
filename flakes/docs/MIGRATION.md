# Coverage and remaining migration

## Included

- Hyprland Lua layout, bindings, animations, window rules and Hyprlock snapshot.
  **Requires Hyprland 0.56+**; a NixOS assertion blocks older versions. No claim
  that the currently unpinned unstable input provides that version.
- Custom Quickshell launcher, notifications, controls, screenshot editor,
  wallpaper studio, Python backend and bundled fonts. Runtime tools for screenshots,
  clipboard, multimedia, Bluetooth, networking and DDC are declared.
- Kitty, lsd, GTK 2/3/4, Zathura, Fish, starship configuration, Neovim Lua snapshot
  with lazy-lock, and all current theme definitions. Fish vi bindings, aliases,
  custom functions, fzf, zoxide and Tide support are retained. Forced DISPLAY/TERM
  and Arch-only package aliases were removed from the copied Fish config.
- Rust theme-set/theme-daemon built through buildRustPackage with Cargo.lock;
  writable theme outputs and Quickshell state are supported.
- NVIDIA open kernel modules (RTX 4070 Super from current Hyprland comments), AMD
  microcode (from package inventory), graphics/firmware, NetworkManager, Bluetooth,
  PipeWire, polkit, keyring, KDE Connect, Android tools, I²C, libvirt and Docker.
  Membership of docker/libvirtd enables powerful host access; review these groups.
- Main desktop, terminal, office, media, torrent, virtualization and development
  packages are declared. `arch-packages.sh` preserves the full inventory for audit.

## Writable config policy (transitional, not fully declarative)

Home Manager manages packages, Fish's generated config, starship, UWSM environment/autostart masks
and session-bound systemd units. Activation seeds missing native config files as writable copies, because
custom theme writers and wallpaper studio modify these paths. Existing files,
symlinks and their contents are never replaced. Thus later source edits do NOT
update already-seeded files automatically, and Nix generation rollback does not
roll back these mutable configs. Back up/move an old config aside yourself before
activation if you want the new snapshot installed; inspect it first. The seeder
will skip old symlink-managed directories rather than modify the original dots.

Follow-up work: split immutable config from generated includes and move Quickshell
state to XDG_STATE_HOME so static config can be managed with HM symlinks; convert
Neovim plugin downloads/builds to Nix derivations. At present Lazy still fetches
plugins on first run, Mason/plugin build hooks may fetch binaries, and Treesitter
may build parsers. These are **not yet all-Nix**, and downloaded Linux binaries may
not run on NixOS. Common compilers/LSPs are declared, not every plugin toolchain.

## Deliberately unresolved / not copied

- Scripts are referenced in bindings (`~/Scripts/launch`, run, notifs.sh,
  waybar_restart.sh, emacsRestart.sh), but ~/Scripts is NOT tracked in this dots
  tree. Copy reviewed source into `flakes/assets/scripts/` and package it as a
  follow-up. Existing local code under ~/Codes (ollama, calculator) is external.
  The external breaks.py and clipboard-sync-host.sh startup calls are not retained;
  their functionality still needs migration as reviewed session-bound services.
- Absolute `/home/chilly` references, wallpapers and monitor settings are retained
  in the snapshots. Changing identity.nix alone does not rewrite these. No personal
  wallpaper media, notes, Firefox profiles, tokens, SSH keys, or VM disk images were
  copied. Themes referencing local wallpaper paths need those media restored.
- aitui is a local application wrapper outside the tracked tree. Its config folder
  contains sessions/backups and potential credentials; none was copied into the
  public Nix store. Package reviewed source/config separately without secrets.
- Aconfmgr, pacman, yay, reflector and Arch base/kernel/driver/service packages are
  replaced by NixOS facilities, not installed. UFW is replaced by the NixOS firewall;
  existing custom rules/port exposure were not inferred. dnsmasq is installed as a
  tool but no global daemon is enabled without a known desired network setup.
- Optional/uncommon packages are looked up explicitly and produce evaluation
  warnings if absent: awww, bluetui, igrep, opencode, superfile, tdf, vis,
  android-studio, Astro LSP, Burp, crunch, mpvpaper, ngrok, prettierd,
  stable-diffusion-cpp, emote, icons/cursors. Resolve every warning before claiming
  parity. Regular Spotify and Prism Launcher are NOT spotify-adblock or the
  offline Prism fork. Helium browser, playit, payload-dumper-go, Juno/Everforest
  themes and Libron font need reviewed derivations/inputs. GTK ThemeManager remains
  provided by the runtime generator. Source Han Korean fonts are provisionally
  covered by Noto CJK; this is not an identical font substitution.
- swaync is removed: Quickshell alone owns notifications. Starship is
  available but not initialized, preserving Tide as the interactive prompt.
  Polkit now uses a session-bound unit; the cursor was changed to Bibata. No SSH
  server, auto-login or greeter was added. KDE Connect opens TCP/UDP 1714–1764
  through its NixOS module; no other application ports were opened.
- Provider API keys (Unsplash/Pexels etc.) must come from a secret mechanism or
  runtime environment, never a flake asset. Don't import aconfmgr's passwd/shadow,
  machine IDs, fstab, private keys or archived host files into Nix configuration.

## Validation performed here

- Fish and Hyprland Lua syntax checks passed.
- Rust theme-manager: 27 tests passed using locked dependencies offline.
- Quickshell Python suite: 46 tests passed with root/services on PYTHONPATH
  (including three UWSM launch/error-handling tests).
- Writable seeding: 2 tests passed (preserve edits, avoid symlink writes).
- Nix evaluation, Nix builds, compositor/QML rendering, hardware brightness,
  locking, GPU drivers and boot/install were NOT tested (Nix unavailable).

## systemd consolidation

- UWSM owns the compositor, graphical-session targets, environment import and
  logout. The copied Hyprland startup callback only calls `uwsm finalize`;
  duplicate daemon launches, obsolete X11 repeat setup and imperative cursor
  setup were removed. Wayland repeat settings already live in the input config.
- `home/session.nix` supervises foreground GUI daemons with explicit executable
  paths, service PATH, restart limits, logout binding and cgroup cleanup.
  Known polkit/KDE Connect XDG autostart entries are masked to avoid double starts.
- KDE Connect's NixOS module handles firewall/uinput only; HM owns its package and
  daemon. The indicator has no tray.target requirement because the custom shell
  has no tray provider; visible tray integration remains a separate UI feature.
- Static wallpaper starts/stops `awww.service` rather than detached subprocesses
  or killall. It is not eagerly enabled: it must stay stopped for video/no-wallpaper
  themes. Video playback remains a managed Quickshell child; do not run another
  wallpaper renderer on startup. Optional package warnings still apply.
- Theme environment updates use `dbus-update-activation-environment --systemd`
  once (updates both environments), rather than a redundant systemctl write too.
- GNOME Keyring retains NixOS's PAM/DBus implementation; duplicate HM service
  removed. Fzf/zoxide/Tide use their HM integrations instead of duplicate package
  entries/manual initialization; zoxide still uses command `c`. Duplicate alias
  definitions and fish_add_path calls were removed. GTK/GPU/desktop exports moved
  from interactive Fish into UWSM environment fragments.
- No linger, automatic login, assumed idle timeout/lock policy, unattended upgrades
  or arbitrary new background services were enabled. Short actions (screenshots,
  controls, lock requests) remain actions rather than unnecessary persistent units.

See README for deployment and existing writable-config migration. The systemd
units and UWSM lifecycle still need Nix evaluation and live login/logout/restart
checks; no services on this machine were started, stopped or reconfigured.
