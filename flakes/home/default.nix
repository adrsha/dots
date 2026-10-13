{ config, pkgs, lib, identity, ... }:
{
  imports = [ ./packages.nix ./session.nix ];
  home = {
    username = identity.username;
    homeDirectory = identity.homeDirectory;
    stateVersion = "25.11";
    sessionPath = [ "$HOME/Scripts" "$HOME/.local/bin" ];
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BROWSER = "firefox";
      TERMINAL = "kitty";
    };
  };
  xdg.enable = true;
  programs.home-manager.enable = true;
  programs.fish = {
    enable = true;
    plugins = [{ name = "tide"; src = pkgs.fishPlugins.tide.src; }];
    interactiveShellInit = builtins.readFile ../assets/config/fish/config.fish;
    shellAliases = {
      # Arch package commands have no safe one-to-one Nix equivalent.
      ins = "nix profile install";
      upd = "nix flake update";
    };
  };
  programs.fzf = { enable = true; enableFishIntegration = true; };
  programs.zoxide = { enable = true; enableFishIntegration = true; options = [ "--cmd" "c" ]; };
  xdg.configFile."starship.toml".source = ../assets/config/starship.toml;

  # Native files must remain writable: theme-set and Quickshell mutate them.
  # Seed missing files only; never overwrite the user's existing configuration.
  home.activation.seedDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.python3}/bin/python3 ${./seed.py} \
      ${../assets/config} ${lib.escapeShellArg config.home.homeDirectory}
  '';
}
