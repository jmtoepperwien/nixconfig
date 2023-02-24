{
  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    agenix = { url = "github:ryantm/agenix"; };
  };

  outputs = { self, nixpkgs, agenix, home-manager, ... }@attrs: rec {
    nixosConfigurations = {
      pi3 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = attrs;
        modules = [
          ./system/pi3.nix
          ./ssh.nix
          ./common.nix
          agenix.nixosModules.default
        ];
      };
      maltepc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
	  ./system/maltepc.nix
          ./common.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.mtoepperwien = import ./homemanager/maltepc.nix;
          }
        ];
      };
      pi4 = nixpkgs.lib.nixosSystem  {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          {
            nixpkgs.config.allowUnsupportedSystem = true;
            nixpkgs.crossSystem.system = "aarch64-linux";
          }
        ];
      };
    };
    images.pi4 = nixosConfigurations.pi4.config.system.build.sdImage;
  };
}
