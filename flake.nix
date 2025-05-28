{
  inputs = {
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixos-25.05";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    yeetmouse = {
      url = "github:AndyFilter/YeetMouse?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      nixpkgs-stable,
      nixpkgs-unstable,
      agenix,
      spicetify-nix,
      home-manager,
      nixos-hardware,
      disko,
      deploy-rs,
      yeetmouse,
      nix-index-database,
      ...
    }@inputs:
    rec {
      nixosConfigurations = {
        installerIso = nixpkgs-stable.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./system/installerIso.nix
          ];
        };
        maltepc = nixpkgs-stable.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            inherit nixpkgs-stable;
          };
          modules = [
            ./system/maltepc.nix
            ./graphical/window_manager.nix
            ./common.nix
            ./ssd.nix
            ./ssh.nix
            agenix.nixosModules.default
            spicetify-nix.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.mtoepperwien = import ./homemanager/maltepc.nix;
              home-manager.extraSpecialArgs = { inherit nixpkgs-unstable; };
            }
            yeetmouse.nixosModules.default
            nix-index-database.nixosModules.nix-index
          ];
        };
        maltexps = nixpkgs-stable.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            inherit nixpkgs-stable;
          };
          modules = [
            ./system/maltexps.nix
            ./graphical/window_manager.nix
            ./common.nix
            ./ssd.nix
            ./programs/ppti.nix
            agenix.nixosModules.default
            spicetify-nix.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.mtoepperwien = import ./homemanager/maltexps.nix;
              home-manager.extraSpecialArgs = { inherit nixpkgs-unstable; };
            }
            yeetmouse.nixosModules.default
            nixos-hardware.nixosModules.dell-xps-13-9370
            nix-index-database.nixosModules.nix-index
          ];
        };
        pi3 = nixpkgs-stable.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs;
            inherit nixpkgs-stable;
          };
          modules = [
            ./system/pi3.nix
            ./ssh.nix
            ./common.nix
            agenix.nixosModules.default
            nix-index-database.nixosModules.nix-index
          ];
        };
        pi4 = nixpkgs-stable.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs;
            inherit nixpkgs-stable;
          };
          modules = [
            ./system/server_variables.nix
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
            ./programs/irc.nix
            ./programs/navidrome.nix

            agenix.nixosModules.default
            nixos-hardware.nixosModules.raspberry-pi-4
            nix-index-database.nixosModules.nix-index
          ];
        };
        server = nixpkgs-stable.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            inherit nixpkgs-stable;
          };
          modules = [
            disko.nixosModules.disko
            ./system/server_variables.nix
            ./system/server.nix
            ./system/hardware/server.nix
            ./ssh.nix
            ./common.nix
            ./programs/nginx.nix
            ./programs/postgresql.nix
            ./programs/gitea.nix
            ./programs/kodi_nfs.nix
            ./programs/usenet.nix
            ./network/proton_wireguard.nix
            ./programs/torrent.nix
            #./programs/irc.nix
            ./programs/navidrome.nix
            ./programs/monitoring.nix
            ./programs/jellyfin.nix
            ./programs/seafile.nix
            ./programs/ldap.nix

            agenix.nixosModules.default
            nix-index-database.nixosModules.nix-index
          ];
        };

      };
      deploy.nodes.server = {
        hostname = "mosihome.duckdns.org";
        profiles.system = {
          sshUser = "mtoepperwien";
          interactiveSudo = true;
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.server;
        };
      };
    };
}
