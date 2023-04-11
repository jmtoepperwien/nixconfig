{ config, lib, pkgs, agenix, ... }:

{
  users.groups."rtorrent" = {};
  users.users."rtorrent" = {
    isSystemUser = true;
    group = "rtorrent";
    extraGroups= [ "usenet" ];
  };

  environment.systemPackages = [ pkgs.flood ];

  services.rtorrent = {
    enable = true;
    user = "rtorrent";
    dataPermissions = "0775";
    downloadDir = "/mnt/kodi_lib/downloads_torrent";
  };

  systemd.services.rtorrent = {
    bindsTo = [ "netns@vpn.service" ];
    requires = [ "network-online.target" ];
    after = [ "protonvpn.service" ];
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/vpn";
    };
  };
}
