# NixOS migration

All new configuration and copied application/theme-manager sources live here.
Standard NixOS (systemd), nixpkgs **nixos-unstable**, and Home Manager master
sharing the same nixpkgs input. This is a migration foundation, **not yet a
fully validated installation or a fully declarative recreation of every feature**.

## Layout

- `flake.nix`: NixOS `arch`, standalone Home Manager `chilly`, theme-manager package.
- `identity.nix`: current username, hostname, home directory.
- `hosts/desktop/`: host and intentionally blocked hardware placeholder.
- `modules/`: system services and AMD/NVIDIA Wayland desktop support.
- `home/`: user packages, Fish integration, systemd session services, safe writable-config activation.
- `assets/config/`: snapshots of current configs (including local changes).
- `assets/theme-manager/`: Rust sources and Cargo lock, no external submodule needed.
- `docs/MIGRATION.md`: coverage, exceptions, remaining work.

## First validation (on a machine with Nix)

Use a path flake until these files are tracked in Git:

```sh
cd flakes
nix flake lock "path:$PWD"
nix flake check "path:$PWD"
nix build "path:$PWD#theme-manager"
nix build "path:$PWD#homeConfigurations.chilly.activationPackage"
```

Review and commit the generated `flake.lock` to pin unstable inputs. No lock was
fabricated: Nix is not installed on the machine where this foundation was created.
The NixOS toplevel deliberately refuses to build before hardware setup. Package
names/options still require Nix evaluation; successful Python/Rust tests are not a
substitute for evaluating/building NixOS. Uncommon packages emit warnings if absent.

## Before installing

1. Back up your home, dotfiles, wallpapers, VM definitions and data. This repository
   does not partition disks or preserve data automatically.
2. From the NixOS installer, mount the **chosen target** at `/mnt` and its boot
   partition at the correct mount point, following the NixOS installation manual.
3. Generate hardware config with `nixos-generate-config --root /mnt`; copy its
   `hardware-configuration.nix` into `hosts/desktop/hardware-configuration.nix`.
   Review it. Do not reuse the archived Arch fstab blindly.
4. Set bootloader settings in `hosts/desktop/default.nix` after choosing your boot
   strategy. For a confirmed UEFI/systemd-boot installation, typically:
   `boot.loader.systemd-boot.enable = true;` and
   `boot.loader.efi.canTouchEfiVariables = true;`. Match the EFI mount point.
5. Review `identity.nix`, AMD/NVIDIA hardware, monitor `HDMI-A-1` at 180 Hz, locale,
   timezone, keyboard and stateVersion baselines. Locale/timezone are not guessed.
6. Evaluate then build without switching:
   `nix build "path:$PWD#nixosConfigurations.arch.config.system.build.toplevel"`.
7. Only after reviewing the result, use `nixos-install --flake "path:$PWD#arch"`
   from the installer. Set the user password with `passwd chilly` in the installed
   system (`nixos-enter --root /mnt` if appropriate), before rebooting. No password
   is embedded in Nix. Start `uwsm start hyprland.desktop` from a TTY; no greeter was selected.

After installation, use `sudo nixos-rebuild build --flake ./flakes#arch`, then
`switch` only when ready. Standalone Home Manager is provided for incremental
migration, but do not activate both standalone and integrated HM on the same home.

Do not run the old symlink bootstrap for Home Manager-managed configs. Existing
configs are preserved by the seed step; see the migration guide before activation.

## systemd desktop session

Start with `uwsm start hyprland.desktop` from a TTY. A future greeter should select
**Hyprland (UWSM)**. Do not start bare Hyprland or manually start
`graphical-session.target`: UWSM owns readiness, environment import and logout.
The copied Lua config runs `uwsm finalize` once; Super+X uses `uwsm stop`.

`home/session.nix` starts foreground Quickshell, theme-daemon, polkit-agent,
KDE Connect daemon and indicator with the graphical session; they stop on logout
and restart on failure. `awww.service` starts/stops on demand through theme-set.
Quickshell owns notifications and its video-wallpaper child process. Applications
launched through the Quickshell launcher use `uwsm app` to get their own systemd
units instead of remaining in Quickshell's cgroup. GNOME Keyring is owned by the
NixOS module/PAM/DBus, not an additional Home Manager daemon.

UWSM config fragments export common HM variables and GUI/GPU settings to the
compositor and activation environment. User tmpfiles create theme state and
screenshot directories. Weekly Nix GC deletes unreferenced generations older
than 30 days; store optimization also uses a weekly timer. Review this retention
policy if you need older rollbacks.

Inspect after deployment:

```sh
systemctl --user status graphical-session.target
systemctl --user status quickshell theme-daemon polkit-agent kdeconnect kdeconnect-indicator
journalctl --user -u quickshell -u theme-daemon -b
systemctl list-timers 'nix-*'
```

**Previously seeded configs are not overwritten.** Before adopting this session
model, manually review/update `~/.config/hypr/hyprland.lua` against the new snapshot:
remove old daemon exec calls, add `uwsm finalize`, and use `uwsm stop` for logout.
Likewise update the copied Fish config and Quickshell backend. Do not run old
startup commands alongside these units. Existing symlink-managed directories
must be migrated explicitly. No live configs were changed by this edit.

Standalone HM installs the user units but does not install NixOS's UWSM system
units, compositor or PAM integration. It is only a complete session setup when
the base OS provides those; standalone HM on its own is not the whole desktop.
