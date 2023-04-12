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

  systemd.services."natpmp-proton" = {
    enable = true;
    description = "Acquire incoming port from protonvpn natpmp";
    requires = [ "protonvpn.service" ];
    bindsTo = [ "protonvpn.service" ];
    serviceConfig = {
      User = "root";
      NetworkNamespacePath = "/var/run/netns/vpn";
      # [TODO: not hardcoded gateway]
      ExecStartPre = pkgs.writers.writeBash "acquire-port-vpn" ''
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 0 udp 60 | grep 'Mapped public port' | sed -E 's/.*Mapped public port ([0-9]+) .*/\1/' > /run/proton_udp_incoming && chown rtorrent:rtorrent /run/proton_udp_incoming"
      '';
      ExecStart = pkgs.writers.writeBash "keep-port-vpn" ''
        eval "while true ; do ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 0 udp 60 && ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 0 tcp 60; sleep 45 ; done"
      '';
      Type = "simple";
      Restart = "always";
    };
  };

  systemd.services.rtorrent = {
    bindsTo = [ "netns@vpn.service" ];
    requires = [ "network-online.target" ];
    after = [ "protonvpn.service" ];
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/vpn";
    };
  };

  systemd.services.flood = {
    enable = true;
    description = "Flood frontend for rtorrent";
    bindsTo = [ "rtorrent.service" "natpmp-proton.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.flood}/bin/flood --rtsocket /run/rtorrent/rpc.sock --port 5678 --host 0.0.0.0";
      Restart = "on-failure";
      Type = "simple";
      User = "rtorrent";
      Group = "rtorrent";
    };
  };
  networking.firewall.allowedTCPPorts = [ 5678 ];
}
