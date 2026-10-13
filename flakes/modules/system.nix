{ pkgs, identity, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Native timer units; no cron jobs or hand-written cleanup scripts.
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 30d"; };
  nix.optimise = { automatic = true; dates = [ "weekly" ]; };
  nixpkgs.config.allowUnfree = true;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  programs.fish.enable = true;
  programs.zsh.enable = true;
  users.users.${identity.username} = {
    isNormalUser = true;
    home = identity.homeDirectory;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "i2c" "libvirtd" "docker" "adbusers" ];
    # Set a password with passwd during installation. No credentials in the store.
  };
  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  programs.virt-manager.enable = true;
  programs.adb.enable = true;
  hardware.i2c.enable = true;
  environment.systemPackages = with pkgs; [ vim dnsmasq dosfstools efibootmgr ];
}
