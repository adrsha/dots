#!/usr/bin/env bash
#
# setup.sh: restore symlinks for everything tracked into DOTS_DIR.
# Primary source of truth is DOTS_DIR/.track-manifest (rel_path<TAB>target
# per line, written by track). If the manifest is missing or incomplete,
# falls back to walking the dots/home/[USER]/... and dots/<rest>/...
# tree directly and resolving [USER] to the current real home, so the
# repo is restorable even without the manifest.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTS_DIR="${DOTS_DIR:-$SCRIPT_DIR}"
MANIFEST="$DOTS_DIR/.track-manifest"
FORCE=0
INSTALL_THEME_MANAGER=0

# same real-user resolution as track, so sudo runs restore to the
# invoking user's home rather than root's
if [[ -n "${SUDO_USER:-}" ]]; then
    real_user="$SUDO_USER"
else
    real_user="${USER:-$(id -un)}"
fi
real_home="$(getent passwd "$real_user" | cut -d: -f6)"
if [[ -z "$real_home" || ! -d "$real_home" ]]; then
    echo "setup.sh: could not resolve home directory for user '$real_user'" >&2
    exit 1
fi
real_home="$(realpath -e -- "$real_home")"

usage() {
    cat <<'EOF'
Usage: ./setup.sh [options]

Options:
  --force           Replace existing unmanaged targets instead of skipping.
  --theme-manager   Build and install theme-set/theme-daemon to ~/.local/bin.
  -h, --help        Show this help.

Package installation is handled separately via aconf, not this script.
EOF
}

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

for arg in "$@"; do
    case "$arg" in
        --force|-f)       FORCE=1 ;;
        --theme-manager)  INSTALL_THEME_MANAGER=1 ;;
        -h|--help)        usage; exit 0 ;;
        *)                warn "unrecognized argument: $arg"; usage; exit 1 ;;
    esac
done

# resolve a rel_path (which may contain the literal "home/[USER]"
# segment) to the real absolute target path on this machine
resolve_target() {
    local rel_path="$1"
    if [[ "$rel_path" == "home/[USER]/"* ]]; then
        printf '%s/%s\n' "$real_home" "${rel_path#home/\[USER\]/}"
    else
        printf '/%s\n' "$rel_path"
    fi
}

restore_link() {
    local rel_path="$1"
    local target="$2"
    local dest="$DOTS_DIR/$rel_path"

    if [[ ! -e "$dest" && ! -L "$dest" ]]; then
        warn "'$rel_path' has no matching file in DOTS_DIR; skipping."
        return 0
    fi

    if [[ -L "$target" ]]; then
        local current
        current="$(readlink -- "$target")"
        if [[ "$current" == "$dest" ]]; then
            log "already linked: $target"
            return 0
        fi
        if [[ "$FORCE" -ne 1 ]]; then
            warn "$target is a symlink to somewhere else; skipping (use --force to replace)."
            return 0
        fi
        rm -f -- "$target"
    elif [[ -e "$target" ]]; then
        if [[ "$FORCE" -ne 1 ]]; then
            warn "$target already exists and is unmanaged; skipping (use --force to replace)."
            return 0
        fi
        rm -rf -- "$target"
    fi

    local target_parent
    target_parent="$(dirname -- "$target")"

    if [[ ! -w "$target_parent" ]] && [[ ! -d "$target_parent" ]]; then
        warn "no write permission on '$target_parent'; re-run with sudo for this entry ($rel_path)."
        return 0
    fi

    mkdir -p -- "$target_parent"
    ln -s -- "$dest" "$target"
    log "linked $target -> $dest"
}

restored_rel_paths=()

if [[ -f "$MANIFEST" ]]; then
    while IFS=$'\t' read -r rel_path target; do
        [[ -z "$rel_path" ]] && continue
        restore_link "$rel_path" "$target"
        restored_rel_paths+=("$rel_path")
    done < "$MANIFEST"
else
    warn "no manifest found at '$MANIFEST'; falling back to tree walk."
fi

# fallback: walk the tree for anything the manifest didn't cover
# (missing manifest entirely, or entries added/edited by hand)
was_restored() {
    local needle="$1" item
    for item in "${restored_rel_paths[@]}"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

while IFS= read -r -d '' entry; do
    rel_path="${entry#"$DOTS_DIR"/}"
    [[ "$rel_path" == .track-manifest ]] && continue
    [[ "$rel_path" == .git || "$rel_path" == .git/* ]] && continue
    was_restored "$rel_path" && continue

    target="$(resolve_target "$rel_path")"
    restore_link "$rel_path" "$target"
done < <(find "$DOTS_DIR" -mindepth 1 -maxdepth 3 -print0 2>/dev/null)

install_theme_manager() {
    if ! command -v cargo >/dev/null 2>&1; then
        warn "cargo is not installed; skipping theme manager build."
        return 0
    fi
    log "Building theme manager..."
    cargo build --release --manifest-path "$DOTS_DIR/themes/theme_manager/Cargo.toml"
    install -Dm755 "$DOTS_DIR/themes/theme_manager/target/release/theme-set" "$real_home/.local/bin/theme-set"
    install -Dm755 "$DOTS_DIR/themes/theme_manager/target/release/theme-daemon" "$real_home/.local/bin/theme-daemon"
    log "Installed theme-set and theme-daemon to $real_home/.local/bin"
}

[[ "$INSTALL_THEME_MANAGER" -eq 1 ]] && install_theme_manager

log "Done. Package installation is handled by aconf, not this script."
