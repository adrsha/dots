set fish_greeting
fish_vi_key_bindings
export FZF_DEFAULT_OPTS=" --prompt='➼ ' --pointer=' ' --marker='󰸞 ' --border-label='󰞘  󰞗' --info=inline:'󰶺  ' --scrollbar= --ansi \
--header='      ' \
--color=bg+:16,bg:-1,spinner:7,hl:1 \
--color=fg+:15,header:1,info:5,pointer:1,label:13 \
--color=marker:2,border:0,fg+:15,fg:0,prompt:5,hl+:1,gutter:-1 --no-separator --cycle --border=rounded --margin=10%,10% -m \
"
export OPENAI_KEY=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
export QT_QPA_PLATFORMTHEME='qt5ct'
export PATH="$PATH:/home/chilly/Themes/scripts:/home/chilly/Scripts:/home/chilly/.cargo/bin:/home/chilly/go/bin"
export BROWSER="firefox"
export VISUAL="nvim"
export MOZ_ENABLE_WAYLAND=1
export EDITOR="nvim"
export XDG_CONFIG_DIR="/home/chilly/.config"
# export DRI_PRIME=1

# echo "\n\033[34m\033[30;44m\033[1m$folder\033[30;m\033[34m" # for pure folders
set --universal pure_show_system_time false
set --universal pure_color_success green
set --universal pure_color_current_directory black
set --universal pure_symbol_prompt "  "
set --universal pure_symbol_reverse_prompt "  "

if status is-interactive
  # alias n="footclient -o "colors.alpha=1" -H nvim"
  alias n="nvim"
  alias ls="lsd --color=always -L"
  alias ll="lsd -l --color=always"
  alias la="lsd -a --color=always"
  alias lla="lsd -la --color=always"
  alias nr="sudo nixos-rebuild switch"
  alias nc="sudo nvim /etc/nixos/configuration.nix"
  alias nd="sudo nix-collect-garbage -d"
  alias hc="nvim /home/chilly/.config/hypr/hyprland.conf"
  alias fc="nvim /home/chilly/.config/fish/config.fish"
  alias cc="cd /home/chilly/Codes/"
  alias lt="ls --tree"
  alias gettoken="cat ~/Documents/gittoken | wl-copy"
  alias bat="bat --color always --plain"
  alias grep='grep --color=auto'
  alias mv='mv -v'
  alias cp='cp -vr'
  alias o='/home/chilly/Scripts/launch'
  alias del='trash-put'
  alias tupd='topgrade --skip-notify -y'
  alias colp='grim -g "$(slurp -p)" -t ppm - | convert - -format \'%[pixel:p{0,0}]\' txt:-'
  alias commit="git add . && git commit -m"
  alias gs="git status"
  alias gr="cd (gitRepos)"
  alias push="git push"
end


function gt
  cd $(cat '/home/chilly/Scripts/data/dirpaths.txt' | fzf)
end

function runc
  make $argv && ./$argv
end

#  function fzf_complete
#      set -l cmdline (commandline)
#      # HACK: Color descriptions manually.
#      complete -C | string replace -r \t'(.*)$' \t(set_color $fish_pager_color_description)'$1'(set_color normal) \
#      | fzf -d \t -1 -0 --ansi --header="   $cmdline  " --height="40%" --tabstop=4 +m --bind 'btab:toggle-up,tab:toggle-down' --layout=reverse \
#      | read -l token
#      # Remove description
#      set token (string replace -r \t'.*' '' -- $token)
#      commandline -rt "$token"
#  end
#
# bind -M insert \t 'fzf_complete; commandline -f repaint'
zoxide init fish --cmd c | source

# bind -M insert jk "if commandline -P; commandline -f cancel; else; set fish_bind_mode default; commandline -f backward-char force-repaint; end"
bind -M insert -m default jk backward-char force-repaint
bind -M insert \cr "~/Scripts/hist"
bind -M insert \cg 'gt'
bind -M insert \ck up-or-search
bind -M insert \cj down-or-search
# Set the cursor shapes for the different vi modes.
set fish_cursor_default     block      blink
set fish_cursor_insert      line       blink
set fish_cursor_replace_one underscore blink
set fish_cursor_visual      block

# python ~/Scripts/todo.py t
