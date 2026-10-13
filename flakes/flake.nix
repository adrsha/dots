{
  description = "Self-contained NixOS unstable and Home Manager migration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      identity = import ./identity.nix;
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in {
      nixosConfigurations.${identity.hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit identity; };
        modules = [
          ./hosts/desktop
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "pre-nix";
            home-manager.extraSpecialArgs = { inherit identity; };
            home-manager.users.${identity.username} = import ./home;
          }
        ];
      };
      homeConfigurations.${identity.username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit identity; };
        modules = [ ./home ];
      };
      packages.${system}.theme-manager = pkgs.callPackage ./packages/theme-manager.nix { };
      checks.${system}.seed = pkgs.runCommand "dotfiles-seed-tests" {
        nativeBuildInputs = [ pkgs.python3 ];
      } ''
        export PYTHONDONTWRITEBYTECODE=1
        python3 -m unittest discover -s ${self}/tests -p test_seed.py -v
        touch $out
      '';
      formatter.${system} = pkgs.nixfmt;
      checks.${system}.home = self.homeConfigurations.${identity.username}.activationPackage;
    };
}
