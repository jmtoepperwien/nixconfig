{ pkgs, ... }:
{
  systemd.services."natpmp-proton" = {
    enable = true;
    description = "Acquire incoming port from protonvpn natpmp";
    requires = [ "protonvpn.service" ];
    after = [ "protonvpn.service" ];
    bindsTo = [ "protonvpn.service" ];
    serviceConfig = {
      TimeoutSec = 60;
      User = "root";
      NetworkNamespacePath = "/var/run/netns/vpn";
      # [TODO: not hardcoded gateway]
      ExecStartPre = pkgs.writers.writeBash "acquire-port-vpn" ''
        echo "getting udp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 udp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*Mapped public port ([0-9]+) .* to local port ([0-9]+) .*/UDPPORTPUBLIC=\1\nUDPPORTPRIVATE=\2/' > /run/proton_incoming"
        echo "getting tcp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 udp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*Mapped public port ([0-9]+) .* to local port ([0-9]+) .*/TCPPORTPUBLIC=\1\nTCPPORTPRIVATE=\2/' >> /run/proton_incoming" && chown rtorrent:rtorrent /run/proton_incoming
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

  systemd.services."natpmp-forward" = {
    enable = true;
    description = "Port forward natpmp open port so that public port matches private port";
    requires = [ "natpmp-proton.service" ];
    after = [ "natpmp-proton.service" ];
    bindsTo = [ "natpmp-proton.service" ];
    serviceConfig = {
      EnvironmentFile = "/run/proton_incoming";
      User = "root";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = pkgs.writers.writeBash "forward-port-vpn-tcp" ''
        echo "forwarding TCP $TCPPORTPRIVATE to $TCPPORTPUBLIC and UDP $UDPPORTPRIVATE to $UDPPORTPUBLIC"
        ${pkgs.nftables}/bin/nft add table ip nat
        ${pkgs.nftables}/bin/nft -- add chain ip nat prerouting { type nat hook prerouting priority -100 \; }
        ${pkgs.nftables}/bin/nft add rule ip nat prerouting tcp dport $TCPPORTPRIVATE redirect to :$TCPPORTPUBLIC
        ${pkgs.nftables}/bin/nft add rule ip nat prerouting udp dport $UDPPORTPRIVATE redirect to :$UDPPORTPUBLIC
      '';
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
  };
}
