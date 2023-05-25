{
  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    agenix = { url = "github:ryantm/agenix"; };
    nixos-hardware = { url = "github:NixOS/nixos-hardware/master"; };
  };

  outputs = { self, nixpkgs, agenix, home-manager, nixos-hardware, ... }@attrs: rec {
    nixosConfigurations = {
      maltepc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
	  ./system/maltepc.nix
          ./graphical/sway.nix
          ./common.nix
          ./ssd.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.mtoepperwien = import ./homemanager/maltepc.nix;
          }
        ];
      };
      maltexps = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          ./system/maltexps.nix
          ./graphical/sway.nix
          ./common.nix
          ./ssd.nix
          ./programs/ppti.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.mtoepperwien = import ./homemanager/maltexps.nix;
          }
          nixos-hardware.nixosModules.dell-xps-13-9370
        ];
      };
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
      pi4 = nixpkgs.lib.nixosSystem  {
        system = "aarch64-linux";
        specialArgs = attrs;
        modules = [
          ./system/pi4.nix
          ./ssh.nix
          ./common.nix
	  ./programs/nginx.nix
	  ./programs/mariadb.nix
	  ./programs/postgresql.nix
	  ./programs/gitea.nix
	  ./programs/kodi_nfs.nix
	  ./programs/usenet.nix
	  ./programs/nextcloud.nix
          ./network/proton_wireguard.nix
          ./programs/torrent.nix

          agenix.nixosModules.default
	  nixos-hardware.nixosModules.raspberry-pi-4
        ];
      };
    };
  };
}
