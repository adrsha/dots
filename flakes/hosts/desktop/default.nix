{ identity, ... }:
{
  imports = [ ./hardware-configuration.nix ../../modules/system.nix ../../modules/desktop.nix ];
  networking.hostName = identity.hostname;
  # Compatibility baseline for a NEW installation; do not bump during upgrades.
  system.stateVersion = "25.11";
}
