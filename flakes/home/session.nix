{ config, pkgs, lib, ... }:
let
  target = "graphical-session.target";
  themeManager = pkgs.callPackage ../packages/theme-manager.nix { };
  # Services cannot depend on an interactive Fish shell to populate their PATH.
  servicePath = lib.concatStringsSep ":" [
    "/run/wrappers/bin"
    (lib.makeBinPath (config.home.packages ++ [ pkgs.systemd pkgs.uwsm pkgs.dbus ]))
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/Scripts"
    "/run/current-system/sw/bin"
  ];
  mkSessionService = description: command: {
    Unit = {
      Description = description;
      After = [ target "dots-tmpfiles.service" ];
      Wants = [ "dots-tmpfiles.service" ];
      PartOf = [ target ];
      Requisite = [ target ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      ExecStart = command;
      Restart = "on-failure";
      RestartSec = 3;
      TimeoutStopSec = 10;
      KillMode = "control-group";
      Environment = [ "PATH=${servicePath}" ];
      Slice = "app.slice";
    };
    Install.WantedBy = [ target ];
  };
in {
  services.kdeconnect.enable = true;
  # HM's indicator option requires tray.target. Quickshell has no tray provider;
  # retain the existing indicator process without making the whole session wait.
  systemd.user.services = {
    dots-tmpfiles = {
      Unit = {
        Description = "Create desktop state directories";
        Before = [ "theme-daemon.service" "quickshell.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemd-tmpfiles --user --create %h/.config/user-tmpfiles.d/dots.conf";
        RemainAfterExit = true;
      };
      Install.WantedBy = [ "default.target" ];
    };
    theme-daemon = mkSessionService "Personal theme watcher" "${themeManager}/bin/theme-daemon";
    quickshell = mkSessionService "Quickshell desktop and notification server" "${pkgs.quickshell}/bin/qs -p %h/.config/quickshell/shell.qml";
    polkit-agent = mkSessionService "Polkit authentication agent"
      "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    kdeconnect-indicator = mkSessionService "KDE Connect indicator"
      "${config.services.kdeconnect.package}/bin/kdeconnect-indicator";
    kdeconnect.Unit.Requisite = [ target ];
    kdeconnect.Service = { Restart = lib.mkForce "on-failure"; RestartSec = 3; };
  } // lib.optionalAttrs (pkgs ? awww) {
    # On-demand, because the theme writer stops awww for video/no-wallpaper.
    # Do not restart on a normal stop or eagerly re-cover a video wallpaper.
    awww = (mkSessionService "Static wallpaper renderer" "${pkgs.awww}/bin/awww-daemon") // {
      Install = { };
    };
  };
  systemd.user.startServices = "sd-switch";

  # UWSM also runs XDG autostart. Keep a single owner for each daemon.
  xdg.configFile = lib.genAttrs [
    "autostart/polkit-gnome-authentication-agent-1.desktop"
    "autostart/org.kde.kdeconnect.daemon.desktop"
    "autostart/org.kde.kdeconnect.nonplasma.desktop"
  ] (_: { text = ''
    [Desktop Entry]
    Type=Application
    Hidden=true
  ''; }) // {
    "user-tmpfiles.d/dots.conf".text = ''
      d %h/.local/state/theme 0700 - - -
      d %h/Pictures/Screenshots 0755 - - -
    '';
    # UWSM imports these before starting GUI services (not Fish-only exports).
    "uwsm/env".text = (lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: value: "export ${name}=${lib.escapeShellArg value}")
      config.home.sessionVariables)) + "\n" + ''
      export MOZ_ENABLE_WAYLAND=1
      export NIXOS_OZONE_WL=1
      export QT_QPA_PLATFORM=wayland
      export QT_QPA_PLATFORMTHEME=qt6ct
    '';
    "uwsm/env-hyprland".text = ''
      export GTK_THEME=ThemeManager
      export XCURSOR_THEME=Bibata-Modern-Classic
      export XCURSOR_SIZE=24
      export HYPRCURSOR_THEME=Bibata-Modern-Classic
      export HYPRCURSOR_SIZE=24
      export LIBVA_DRIVER_NAME=nvidia
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export GBM_BACKEND=nvidia-drm
      export __GL_GSYNC_ALLOWED=1
      export _GL_VRR_ALLOWED=1
    '';
  };
}
