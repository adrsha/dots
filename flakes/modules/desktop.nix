{ pkgs, lib, ... }:
{
  programs.hyprland = { enable = true; withUWSM = true; };
  programs.uwsm.waylandCompositors.hyprland = {
    prettyName = "Hyprland";
    comment = "Hyprland managed by systemd/UWSM";
    binPath = "/run/wrappers/bin/Hyprland";
  };
  # The existing configuration uses Hyprland's native Lua API.
  assertions = [{
    assertion = lib.versionAtLeast pkgs.hyprland.version "0.56";
    message = "The imported Hyprland Lua config requires Hyprland >= 0.56. Update nixpkgs or port the configuration before deployment.";
  }];
  hardware.graphics = { enable = true; enable32Bit = true; };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true; # Current config identifies an RTX 4070 Super.
    modesetting.enable = true;
    nvidiaSettings = true;
  };
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  security.polkit.enable = true;
  security.pam.services.hyprlock = { };
  services.gnome.gnome-keyring.enable = true;
  # NixOS owns firewall/uinput; HM installs the package and owns its daemon.
  programs.kdeconnect = { enable = true; package = null; };
  fonts.packages = with pkgs; [
    nerd-fonts.envy-code-r nerd-fonts.jetbrains-mono
    noto-fonts noto-fonts-cjk-sans noto-fonts-cjk-serif noto-fonts-color-emoji
  ];
  # Start with `uwsm start hyprland.desktop` from a TTY, not bare Hyprland.
}
