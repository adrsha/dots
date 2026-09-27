export MANPAGER="bat --color always --tabs 4 --theme ansi -l md --wrap auto"
export DISPLAY=:0
export RUST_BACKTRACE=full
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt6ct

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XCURSOR_SIZE=24

export EDITOR=nvim
export VISUAL=nvim
export BROWSER=firefox

export FZF_DEFAULT_OPTS="--height=80% --layout=reverse --info=inline --border --margin=1 --padding=1 --wrap --gap=1 --no-separator --pointer=✦ --color='gutter:-1,fg+:2,fg:7'"

export HYRCURSOR_THEME="Bibata-Modern_Classic"
export HYRCURSOR_TRACE=1
export HYRCURSOR_SIZE=24

export WLR_NO_HARDWARE_CURSORS=1
export LIBVA_DRIVER_NAME=nvidia
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GL_GSYNC_ALLOWED=1
export _GL_VRR_ALLOWED=1
export WLR_RENDERER_ALLOW_SOFTWARE=1

export TERM=xterm
export TERMINAL=kitty


export PATH="$HOME/Scripts:$HOME/.local/bin:$PATH"

if command -v lsd >/dev/null 2>&1; then
    alias l='lsd -L'
    alias ls='lsd -L'
    alias la='lsd -A'
    alias ll='lsd -lA --date relative --sort git'
    alias lt='lsd --tree'
    alias lr='lsd -R'
else
    alias la='ls -A'
    alias ll='ls -lA'
fi

alias ..="cd ../"
alias ..="cd ../"
alias cp='cp -ir'
alias mv='cp -i'
alias mkdir='mkdir -p'
alias o="$HOME/Scripts/launch"

# This overrides the previous mv alias, matching your Fish config.

alias mv='mv'

alias fs='df -h -x squashfs -x tmpfs -x devtmpfs'

alias n='nvim'
alias bc="nvim $HOME/.bashrc"
alias fc="nvim $HOME/.config/fish/config.fish"
alias hc="nvim $HOME/.config/hypr/hyprland.lua"

alias f='n $(find . -type f | fzf)'
alias o="$HOME/Scripts/launch"
alias t="nvim $HOME/Notes/index.md"

alias bat='bat --theme=ansi'
alias yay='yay --color=auto'

alias pyv='python venv ./bin/activate.fish'

alias ins='yay --color=auto -S'
alias upd='yay --color=auto -Syu'

alias mi='matugen --contrast -1 image'
alias calc="$HOME/Codes/rumat/target/release/rustCalc"

alias uni='yay --color=auto -Rcns'

alias ls='lsd'
alias la='lsd -A'
alias lf='lsd --tree --depth=1'
alias lt='lsd --tree --depth=2'

alias nmr='sudo systemctl restart NetworkManager --now'
alias nm='nmtui'

alias fs='sudo du -h -d 2 | sort -rh'

alias glpush='cat ~/Documents/gitlabtoken | wl-copy; git push origin "$(git branch --show-current)"'
alias ghpush='cat ~/Documents/githubtoken | wl-copy; git push origin "$(git branch --show-current)"'

alias pubip='curl -4 ifconfig.me | wl-copy'
alias pacclean='sudo paccache -ruk0'

clrdir() {
    local show_preview=false
    local -a exclude_patterns=()

    ```
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--preview)
                show_preview=true
                shift
                ;;
            -x|--exclude)
                if [[ -n "$2" ]]; then
                    exclude_patterns+=("$2")
                    shift 2
                else
                    echo "❌ --exclude requires a pattern"
                    return 1
                fi
                ;;
            *)
                shift
                ;;
        esac
    done

    local -a all_items=()
    local -a items_to_delete=()

    # Include hidden files, excluding . and ..
    mapfile -t all_items < <(ls -A)

    for item in "${all_items[@]}"; do
        local should_exclude=false

        for pattern in "${exclude_patterns[@]}"; do
            if [[ "$item" == $pattern ]]; then
                should_exclude=true
                break
            fi
        done

        if [[ "$should_exclude" == false ]]; then
            items_to_delete+=("$item")
        fi
    done

    if [[ ${#items_to_delete[@]} -eq 0 ]]; then
        echo "📁 Directory is already empty (or all items excluded)"
        return
    fi

    if [[ "$show_preview" == true ]]; then
        echo "📋 Items to be deleted:"
        printf '  %s\n' "${items_to_delete[@]}"
        echo
    fi

    echo "🧹 Cleaning..."

    if rm -rf -- "${items_to_delete[@]}" 2>/dev/null; then
        echo "✅ Deleted ${#items_to_delete[@]} item(s)"
        else
            echo "❌ Some items could not be deleted"
            return 1
    fi
    ```

}

# ─────────────────────────────────────────────────────────────

# mkdir + cd

# ─────────────────────────────────────────────────────────────

tk() {
    mkdir -p -- "$@" && cd -- "$@"
}

# ─────────────────────────────────────────────────────────────
# Bash readline
# ─────────────────────────────────────────────────────────────

# Fish's:
# bind -M insert jk ...
#

# Bash doesn't have Fish's modal editing model.
# If you're using vi editing mode, this provides a similar
# "jk -> escape" behavior.

set -o vi

# Bash's readline cannot directly reproduce the Fish binding
# above without additional readline configuration.

# ─────────────────────────────────────────────────────────────
# fzf cd helper
# ─────────────────────────────────────────────────────────────

gt() {
    local commandline
    local dir
    local fzf_query
    local prefix
    local result

    ```
    # fzf's Bash integration provides these helpers when loaded.
    if ! type __fzf_parse_commandline >/dev/null 2>&1; then
        echo "fzf shell integration is not loaded"
        return 1
    fi

    commandline=$(__fzf_parse_commandline)

    dir=$(printf '%s\n' "$commandline" | awk '{print $1}')
    fzf_query=$(printf '%s\n' "$commandline" | awk '{print $2}')
    prefix=$(printf '%s\n' "$commandline" | awk '{print $3}')

    export dir
    export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} --reverse --walker=dir,follow,hidden --scheme=path ${FZF_ALT_C_OPTS:-} --no-multi --print0"

    unset FZF_DEFAULT_OPTS_FILE
    export FZF_DEFAULT_COMMAND="${FZF_ALT_C_COMMAND:-}"

    result=$(
        eval "$(__fzfcmd)" \
            --query="$fzf_query" \
            --walker-root="$dir" |
            tr '\0' '\n'
        )

        if [[ -n "$result" ]]; then
            cd -- "$result" || return
        fi
        ```

}

# ─────────────────────────────────────────────────────────────
# Theme
# ─────────────────────────────────────────────────────────────

theme() {
    command theme-set "$1" &&
        source "$HOME/.config/fish/conf.d/theme_vars.fish"
}

if [[ -f "$HOME/.config/fish/conf.d/theme_vars.fish" ]]; then
    source "$HOME/.config/fish/conf.d/theme_vars.fish"
fi

# ─────────────────────────────────────────────────────────────
# zoxide
# ─────────────────────────────────────────────────────────────

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash --cmd c)"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
