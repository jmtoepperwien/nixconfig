{
  inputs = {
    nixpkgs-stable = { url = "github:nixos/nixpkgs/nixos-24.11"; };
    nixpkgs-unstable = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    home-manager = { url = "github:nix-community/home-manager/release-24.11"; inputs.nixpkgs.follows = "nixpkgs-stable"; };
    agenix = { url = "github:ryantm/agenix"; };
    nixos-hardware = { url = "github:NixOS/nixos-hardware/master"; };
  };

  outputs = { self, nixpkgs-stable, nixpkgs-unstable, agenix, home-manager, nixos-hardware, ... }@inputs: rec {
    nixosConfigurations = {
      maltepc = nixpkgs-stable.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; inherit nixpkgs-stable; };
        modules = [
          ./system/maltepc.nix
          ./graphical/window_manager.nix
          ./common.nix
          ./ssd.nix
          ./ssh.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.mtoepperwien = import ./homemanager/maltepc.nix;
            home-manager.extraSpecialArgs = { inherit nixpkgs-unstable; };
          }
        ];
      };
      maltexps = nixpkgs-stable.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; inherit nixpkgs-stable; };
        modules = [
          ./system/maltexps.nix
          ./graphical/window_manager.nix
          ./common.nix
          ./ssd.nix
          ./programs/ppti.nix
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.mtoepperwien = import ./homemanager/maltexps.nix;
            home-manager.extraSpecialArgs = { inherit nixpkgs-unstable; };
          }
          nixos-hardware.nixosModules.dell-xps-13-9370
        ];
      };
      pi3 = nixpkgs-stable.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; inherit nixpkgs-stable; };
        modules = [
          ./system/pi3.nix
          ./ssh.nix
          ./common.nix
          agenix.nixosModules.default
        ];
      };
      pi4 = nixpkgs-stable.lib.nixosSystem  {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; inherit nixpkgs-stable; };
        modules = [
          ./system/pi4.nix
          ./ssh.nix
          ./common.nix
          ./programs/nginx.nix
          ./programs/postgresql.nix
          ./programs/gitea.nix
          ./programs/kodi_nfs.nix
          ./programs/usenet.nix
          ./network/proton_wireguard.nix
          ./programs/torrent.nix
          ./programs/irssi.nix
          ./programs/irc.nix
          ./programs/immich.nix
          ./programs/navidrome.nix

          agenix.nixosModules.default
          nixos-hardware.nixosModules.raspberry-pi-4
        ];
      };
      server = nixpkgs-stable.lib.nixosSystem  {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; inherit nixpkgs-stable; };
        modules = [
          ./ssh.nix
          ./common.nix
          ./programs/nginx.nix
          ./programs/postgresql.nix
          ./programs/gitea.nix
          ./programs/kodi_nfs.nix
          ./programs/usenet.nix
          ./network/proton_wireguard.nix
          ./programs/torrent.nix
          ./programs/irssi.nix
          ./programs/irc.nix
          ./programs/immich.nix
          ./programs/navidrome.nix

          agenix.nixosModules.default
        ];
      };

    };
  };
}
