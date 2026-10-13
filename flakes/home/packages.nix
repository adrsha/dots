{ pkgs, lib, ... }:
let
  # Keep uncommon/AUR replacements visible if unstable renames/removes them.
  optionalNames = [
    "awww" "bluetui" "igrep" "opencode" "superfile" "tdf" "vis"
    "android-studio" "astro-language-server" "burpsuite" "crunch"
    "mpvpaper" "ngrok" "prettierd" "stable-diffusion-cpp" "emote"
    "nordzy-icon-theme" "oreo-cursors" "tela-icon-theme" "bibata-cursors"
  ];
  available = builtins.filter (name: builtins.hasAttr name pkgs) optionalNames;
  missing = builtins.filter (name: !(builtins.hasAttr name pkgs)) optionalNames;
in {
  warnings = lib.optional (missing != [])
    "Migration packages unavailable in this nixpkgs revision: ${lib.concatStringsSep ", " missing}. See flakes/docs/MIGRATION.md.";
  home.packages = (with pkgs; [
    alacritty autoconf automake bat bottom btop cmatrix
    ddcutil discord dust fakeroot fd firefox git glow grim
    hyprlock hyprpicker imv jdk21 jq kitty libreoffice lsd
    mesa-demos miniserve mpv neovim nwg-look openssh
    progress qbittorrent qemu qt6ct quickshell ruff rustup shfmt
    slurp starship stylua subversion sysfsutils
    tealdeer tree-sitter typescript-language-server ueberzugpp unzip
    virt-viewer vlc wev yt-dlp zathura zip
    wl-clipboard ffmpeg playerctl xdg-utils libnotify polkit_gnome
    gtk3 bluez networkmanager wireplumber curl wget
    gcc gnumake pkg-config nodejs python3 python3Packages.pip
    lua-language-server nil nixfmt vscode-langservers-extracted
    emacs spotify prismlauncher
  ]) ++ map (name: builtins.getAttr name pkgs) available
     ++ [ (pkgs.callPackage ../packages/theme-manager.nix { }) ];
}
