{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.par2cmdline ];
  users.groups."usenet" = {};

  # Sonarr
  users.groups."sonarr" = {};
  users.users."sonarr" = {
    isSystemUser = true;
    group = "sonarr";
    extraGroups = [ "usenet" ];
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
    extraGroups = [ "usenet" ];
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
    extraGroups = [ "usenet" ];
  };

  services.readarr = {
    enable = true;
    openFirewall = true;
  };

  # Prowlarr
  users.groups."prowlarr" = {};
  users.users."prowlarr" = {
    isSystemUser = true;
    group = "prowlarr";
    extraGroups = [ "usenet" ];
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
  networking.firewall.allowedTCPPorts = [ 6789 ];
}
