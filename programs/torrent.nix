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
    configText = ''
      dht.mode.set = auto
      protocol.pex.set = yes

      trackers.use_udp.set = yes

      system.umask.set = 0002
    '';
  };

  systemd.services."natpmp-proton" = {
    enable = true;
    description = "Acquire incoming port from protonvpn natpmp";
    requires = [ "protonvpn.service" ];
    after = [ "protonvpn.service" ];
    bindsTo = [ "protonvpn.service" ];
    serviceConfig = {
      User = "root";
      NetworkNamespacePath = "/var/run/netns/vpn";
      # [TODO: not hardcoded gateway]
      ExecStartPre = pkgs.writers.writeBash "acquire-port-vpn" ''
        echo "getting udp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 udp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*to local port ([0-9]+) .*/UDPPORT=\1/' > /run/proton_incoming"
        echo "getting tcp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 tcp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*to local port ([0-9]+) .*/TCPPORT=\1/' >> /run/proton_incoming && chown rtorrent:rtorrent /run/proton_incoming"
      '';
      ExecStart = pkgs.writers.writeBash "keep-port-vpn" ''
       echo "looping to keep"
        while true ; do
          ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 udp 60 && ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 tcp 60
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
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      EnvironmentFile = "/run/proton_incoming";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = lib.mkForce (pkgs.writers.writeBash "start-rtorrent" ''
        echo "${rtorrentPackage}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORT-$TCPPORT -o dht.port.set=$UDPPORT
"
        ${rtorrentPackage}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORT-$TCPPORT -o dht.port.set=$UDPPORT
      '');
    };
  };

  systemd.services.flood = {
    enable = true;
    description = "Flood frontend for rtorrent";
    bindsTo = [ "rtorrent.service" ];
    after = [ "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
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
