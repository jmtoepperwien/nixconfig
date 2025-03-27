{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = [ pkgs.par2cmdline ];
  users.groups."media" = { };

  # Sonarr
  users.groups."sonarr" = { };
  users.users."sonarr" = {
    isSystemUser = true;
    group = "sonarr";
    extraGroups = [
      "media"
      "rtorrent"
    ];
  };

  services.sonarr = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.sonarr;
    openFirewall = true;
  };

  # Radarr
  users.groups."radarr" = { };
  users.users."radarr" = {
    isSystemUser = true;
    group = "radarr";
    extraGroups = [
      "media"
      "rtorrent"
    ];
  };

  services.radarr = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.radarr;
    openFirewall = true;
  };

  # Lidarr
  users.groups."lidarr" = { };
  users.users."lidarr" = {
    isSystemUser = true;
    group = "lidarr";
    extraGroups = [
      "media"
      "rtorrent"
    ];
  };

  services.lidarr = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.lidarr;
    openFirewall = true;
  };

  # Readarr
  users.groups."readarr" = { };
  users.users."readarr" = {
    isSystemUser = true;
    group = "readarr";
    extraGroups = [
      "media"
      "rtorrent"
    ];
  };

  services.readarr = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.readarr;
    openFirewall = true;
  };
  ## Calibre Server for Readarr
  services.calibre-server = {
    enable = false;
    user = "readarr";
    group = "readarr";
    libraries = [ "${config.server.media_folder}/books/" ];
  };

  # Prowlarr
  users.groups."prowlarr" = { };
  users.users."prowlarr" = {
    isSystemUser = true;
    group = "prowlarr";
    extraGroups = [
      "media"
      "rtorrent"
    ];
  };
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.prowlarr = {
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/vpn";
    };
  };

  # Sabnzbd
  users.users."sabnzbd" = {
    isSystemUser = true;
    group = lib.mkForce "media";
  };

  services.sabnzbd = {
    enable = true;
    group = "media";
  };

  services.ombi = {
    enable = true;
    openFirewall = true;
    port = 5001;
  };
  networking.firewall.allowedTCPPorts = [ 6789 ];
}
