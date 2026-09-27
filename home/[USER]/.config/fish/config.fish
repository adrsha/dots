if test -f ~/.config/dots/env.fish
    source ~/.config/dots/env.fish
else
    set -gx DOTS_DIR ~/dots
end

set -U fish_greeting
fish_vi_key_bindings


export MANPAGER="bat --color always --tabs 4 --theme ansi -l md --wrap auto"
export DISPLAY=:0
export RUST_BACKTRACE=full
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt6ct

export XDG_CONFIG_HOME=$HOME/.config
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
export HYRCURSOR_SIZE=24;

export WLR_NO_HARDWARE_CURSORS=1
export LIBVA_DRIVER_NAME=nvidia
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GL_GSYNC_ALLOWED=1
export _GL_VRR_ALLOWED=1
export WLR_RENDERER_ALLOW_SOFTWARE=1
export TERM=xterm
export TERMINAL=kitty

fish_add_path path $HOME/Scripts/
fish_add_path path $HOME/.local/bin
# fish_add_path path $HOME/.config/emacs/bin

if status is-interactive
    if lsd --version > /dev/null
        alias l="lsd -L";
        alias ls="lsd -L";
        alias la="lsd -A";
        alias ll="lsd -lA --date relative --sort git";
        alias lt="lsd --tree";
        alias lr="lsd -R";
    else
        alias la='ls -A'
        alias ll='ls -lA'
    end


    alias cp='cp -ir'
    alias mv='cp -i'
    alias mkdir='mkdir -p'
    alias o='~/Scripts/launch'
    alias mv='mv'
    alias fs='df -h -x squashfs -x tmpfs -x devtmpfs'

    alias n='nvim'
    alias fc='nvim ~/.config/fish/config.fish'
    alias hc='nvim ~/.config/hypr/hyprland.lua'
    alias ac='nvim ~/.config/alacritty/alacritty.toml'
    alias f='n $(find | fzf)';
    alias o="~/Scripts/launch";
    alias t="nvim ~/Notes/index.md";
    alias bat='bat --theme=ansi'
    alias yay='yay --color=auto'
    alias pyv='python venv ./bin/activate.fish'
    alias ins='yay --color=auto -S'
    alias upd='yay --color=auto -Syu'
    alias mi="matugen --contrast -1 image";
    alias calc='~/Codes/rumat/target/release/rustCalc'
    alias uni='yay --color=auto -Rcns'
    alias ls='lsd'
    alias nmr='sudo systemctl restart NetworkManager --now'
    alias nm='nmtui'
    alias fs='sudo du -h -d 2 | sort -rh'
    alias la='lsd -A'
    alias lf='lsd --tree --depth=1'
    alias lt='lsd --tree --depth=2'
    alias glpush='cat ~/Documents/gitlabtoken | wl-copy; git push origin $(git branch --show-current)'
    alias ghpush='cat ~/Documents/githubtoken | wl-copy; git push origin $(git branch --show-current)'
    alias pubip='curl -4 ifconfig.me | wl-copy'
    alias pacclean='sudo paccache -ruk0'

end

function clrdir -d "Clear directory contents with optional preview and exclusions"
    set -l show_preview false
    set -l exclude_patterns

    # Parse arguments
    for arg in $argv
        switch $arg
            case -p --preview
                set show_preview true
            case -x --exclude
                # Next argument will be the exclude pattern
                continue
            case '*'
                if test "$argv[(math (contains -i -- $arg $argv) - 1)]" = "-x" -o "$argv[(math (contains -i -- $arg $argv) - 1)]" = "--exclude"
                    set -a exclude_patterns $arg
                end
        end
    end

    # Get all items (including hidden, excluding . and ..)
    set -l all_items (ls -A)
    set -l items_to_delete

    # Filter out excluded patterns
    for item in $all_items
        set -l should_exclude false
        for pattern in $exclude_patterns
            if string match -q $pattern $item
                set should_exclude true
                break
            end
        end
        if not $should_exclude
            set -a items_to_delete $item
        end
    end

    if test (count $items_to_delete) -eq 0
        echo "📁 Directory is already empty (or all items excluded)"
        return
    end

    # Show preview if requested
    if test $show_preview = true
        echo "📋 Items to be deleted:"
        printf "  %s\n" $items_to_delete
        echo
    end

    echo "🧹 Cleaning..."
    rm -rf -- $items_to_delete 2>/dev/null
    and echo "✅ Deleted "(count $items_to_delete)" item(s)"
    or echo "❌ Some items could not be deleted"
end

function tk
    mkdir -p $argv; 
    cd $argv;
end

set fish_cursor_insert line
set fish_cursor_default block
set fish_cursor_visual block

function fish_user_key_bindings
    bind -M insert jk "if commandline -P; commandline -f cancel; else; set fish_bind_mode default; commandline -f backward-char force-repaint; end"
end

function gt
    set -l commandline (__fzf_parse_commandline)
    set -lx dir $commandline[1]
    set -l fzf_query $commandline[2]
    set -l prefix $commandline[3]

    set -lx FZF_DEFAULT_OPTS (__fzf_defaults \
        "--reverse --walker=dir,follow,hidden --scheme=path" \
        "$FZF_ALT_C_OPTS --no-multi --print0")

    set -lx FZF_DEFAULT_OPTS_FILE
    set -lx FZF_DEFAULT_COMMAND "$FZF_ALT_C_COMMAND"

    if set -l result (eval (__fzfcmd) --query=$fzf_query --walker-root=$dir | string split0)
        cd -- $result
        commandline -rt -- $prefix
    end

    commandline -f repaint

end

function theme
    command theme-set $argv[1]
    and source ~/.config/fish/conf.d/theme_vars.fish
end

if test -f ~/.config/fish/conf.d/theme_vars.fish
    source ~/.config/fish/conf.d/theme_vars.fish
end

zoxide init fish --cmd c| source
