{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.par2cmdline ];
  users.groups."usenet" = {};

  # Sonarr
  users.groups."sonarr" = {};
  users.users."sonarr" = {
    isSystemUser = true;
    group = "sonarr";
    extraGroups = [ "usenet" "rtorrent" ];
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
  };

  # Radarr
  users.groups."radarr" = {};
  users.users."radarr" = {
    isSystemUser = true;
    group = "radarr";
    extraGroups = [ "usenet" "rtorrent" ];
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
  };

  # Readarr
  users.groups."readarr" = {};
  users.users."readarr" = {
    isSystemUser = true;
    group = "readarr";
    extraGroups = [ "usenet" "rtorrent" ];
  };

  services.readarr = {
    enable = true;
    openFirewall = true;
  };
  ## Calibre Server for Readarr
  services.calibre-server = {
    enable = true;
    user = "readarr";
    group = "readarr";
    libraries = [ "/mnt/kodi_lib/books/" ];
  };

  # Prowlarr
  users.groups."prowlarr" = {};
  users.users."prowlarr" = {
    isSystemUser = true;
    group = "prowlarr";
    extraGroups = [ "usenet" "rtorrent" ];
  };
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  # Sabnzbd
  users.users."sabnzbd" = {
    isSystemUser = true;
    group = lib.mkForce "usenet";
  };

  services.sabnzbd = {
    enable = true;
    group = "usenet";
  };

  services.ombi = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall.allowedTCPPorts = [ 6789 5000 ];
}
