{ ... }:
{
  # Replace this file with nixos-generate-config's output for the target machine.
  # Deliberately no guessed root filesystem, EFI mount, or bootloader settings.
  assertions = [{
    assertion = false;
    message = "Replace flakes/hosts/desktop/hardware-configuration.nix with target hardware configuration and configure a bootloader before building/installing NixOS.";
  }];
}
