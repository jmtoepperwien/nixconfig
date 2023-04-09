{ config, lib, pkgs, agenix, ... }:

{
  users.groups."transmission" = {};
  users.users."transmission" = {
    isSystemUser = true;
    group = "transmission";
    extraGroups= [ "usenet" ];
  };

  services.transmission = {
    enable = true;
    user = "transmission";
    group = "usenet"; # [TODO: global rename]
    settings = {
      incomplete-dir = /mnt/kodi_lib/incomplete;
      download-dir = /mnt/kodi_lib/completed;
    };
    openRPCPort = true;
  };
  systemd.services.transmission = {
    bindsTo = [ "netns@vpn.service" ];
    requires = [ "network-online.target" ];
    after = [ "protonvpn.service" ];
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/vpn";
    };
  };
}
