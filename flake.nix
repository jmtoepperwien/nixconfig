{
  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    agenix = { url = "github:ryantm/agenix"; };
  };

  outputs = { self, nixpkgs, agenix, ... }@attrs: {
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
        ];
      };
    };
  };
}
