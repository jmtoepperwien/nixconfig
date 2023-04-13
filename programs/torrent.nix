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
    bindsTo = [ "protonvpn.service" "rtorrent.service" ];
    serviceConfig = {
      User = "root";
      NetworkNamespacePath = "/var/run/netns/vpn";
      # [TODO: not hardcoded gateway]
      ExecStart = pkgs.writers.writeBash "get-port-vpn" ''
        echo "getting udp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 0 udp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*Mapped public port ([0-9]+) .*/UDPPORT=\1/' > /run/proton_incoming"
        echo "getting tcp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 0 tcp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*Mapped public port ([0-9]+) .*/TCPPORT=\1/' >> /run/proton_incoming"
        echo "looping to keep"
        while true ; do
          ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 0 udp 60 && ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 0 tcp 60
          sleep 45
        done
      '';
      Type = "simple";
      Restart = "always";
    };
  };

  systemd.services.rtorrent = let
    configFile = pkgs.writeText "rtorrent.rc" config.services.rtorrent.configText;
    rtorrentPackage = config.services.rtorrent.package;
  in {
    bindsTo = [ "netns@vpn.service" ];
    requires = [ "network-online.target" "protonvpn.service" "natpmp-proton.service" ];
    after = [ "protonvpn.service" "natpmp-proton.service" ];
    serviceConfig = {
      EnvironmentFile = "/run/proton_incoming";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = lib.mkForce "${rtorrentPackage}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORT-$TCPPORT -o dht.port.set=$UDPPORT";
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
