set fish_greeting

fish_vi_key_bindings
export FZF_DEFAULT_OPTS=" --prompt='➼ ' --pointer=' ' --marker='󰸞 ' --border-label='󰞘  󰞗' --info=inline:'󰶺  ' --scrollbar= --ansi \
--header='        ' \
--color=bg+:#15121c,bg:-1,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg+:5,header:#f38ba8,info:#cba6f7,pointer:1,label:13 \
--color=marker:2,border:0,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8,gutter:-1 --no-separator --cycle --border=rounded --margin=10%,10% -m \
"
export QT_QPA_PLATFORMTHEME='qt5ct'
export PATH="$PATH:/home/chilly/Themes/scripts:/home/chilly/Scripts"
export BROWSER="firefox"
export VISUAL="nvim"
export MOZ_ENABLE_WAYLAND=1
export EDITOR="nvim"
export DRI_PRIME=1

set --universal pure_color_success green
set --universal pure_color_current_directory black
set --universal pure_symbol_prompt "  "
set --universal pure_symbol_reverse_prompt "  "

if status is-interactive
  alias cleanram="sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'"
  # alias n="footclient -o "colors.alpha=1" -H nvim"
  alias n="nvim"
  alias ls="exa --color=always"
  alias ll="exa -l --color=always"
  alias la="exa -a --color=always"
  alias lla="exa -la --color=always"
  alias hc="nvim /home/chilly/.config/hypr/hyprland.conf"
  alias fc="nvim /home/chilly/.config/fish/config.fish"
  alias cc="cd /home/chilly/Codes/"
  alias pac="sudo pacman -Sy --color always"
  alias fpac="fzpac S"
  alias clean='sudo pacman --color always -Rns $(pacman -Qtdq)'
  alias uni="sudo pacman -Rcns --color always"
  alias yay="yay --color=always"
  alias lt="ls --tree"
  alias re="sh ~/Templates/terminal/terminal_theme.sh"
  alias iv="lsix"
  alias gettoken="cat ~/Documents/gittoken | wl-copy"
  alias bat="bat --color always --plain"
  alias grep='grep --color=auto'
  alias mv='mv -v'
  alias cp='cp -vr'
  alias o='sh /home/chilly/Scripts/launch'
  alias del='trash-put'
  alias tupd='topgrade --skip-notify -y'
  alias upd='sudo pacman -Suuy'
  alias commit="git add . && git commit -m"
  alias gs="git status"
  alias push="git push"
end


function gt
  cd $(bat '/home/chilly/Scripts/data/dirpaths.txt' | fzf --ansi )
end

function of
  o $(bat '/home/chilly/Scripts/data/filepaths.txt' | fzf --ansi )
end


#
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
bind -M insert \co 'of'
bind -M insert \cg 'gt'
# Set the cursor shapes for the different vi modes.
set fish_cursor_default     block      blink
set fish_cursor_insert      line       blink
set fish_cursor_replace_one underscore blink
set fish_cursor_visual      block
