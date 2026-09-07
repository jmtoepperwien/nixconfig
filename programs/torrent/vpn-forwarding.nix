{ pkgs, ... }:
let
  gateway = "10.2.0.1";
  privatePort = "34828";
  portsFile = "/run/proton_incoming";

  # Requests/renews a NAT-PMP mapping for one protocol and prints
  # "PUBLIC PRIVATE" parsed from natpmpc's "Mapped public port" line.
  natpmpRequest = pkgs.writeShellScript "natpmp-request" ''
    proto="$1"
    ${pkgs.libnatpmp}/bin/natpmpc -g ${gateway} -a 0 ${privatePort} "$proto" 60 \
      | ${pkgs.gnugrep}/bin/grep 'Mapped public port' \
      | ${pkgs.gnused}/bin/sed -E 's/.*Mapped public port ([0-9]+) .* to local port ([0-9]+) .*/\1 \2/'
  '';

  # (Re)creates the nat table from scratch based on the current
  # ports file, so it can be safely re-run whenever the mapped
  # public port changes.
  applyNat = pkgs.writers.writeBash "apply-natpmp-forward" ''
    set -euo pipefail
    source ${portsFile}
    ${pkgs.nftables}/bin/nft delete table ip nat 2>/dev/null || true
    ${pkgs.nftables}/bin/nft add table ip nat
    ${pkgs.nftables}/bin/nft -- add chain ip nat prerouting { type nat hook prerouting priority -100 \; }
    ${pkgs.nftables}/bin/nft add rule ip nat prerouting tcp dport $TCPPORTPRIVATE redirect to :$TCPPORTPUBLIC
    ${pkgs.nftables}/bin/nft add rule ip nat prerouting udp dport $UDPPORTPRIVATE redirect to :$UDPPORTPUBLIC
  '';
in
{
  systemd.services."natpmp-proton" = {
    enable = true;
    description = "Acquire and keep alive an incoming port from protonvpn natpmp";
    requires = [ "protonvpn.service" ];
    after = [ "protonvpn.service" ];
    bindsTo = [ "protonvpn.service" ];
    serviceConfig = {
      TimeoutSec = 60;
      User = "root";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStartPre = pkgs.writers.writeBash "acquire-port-vpn" ''
        set -euo pipefail
        echo "getting udp"
        read -r UDPPORTPUBLIC UDPPORTPRIVATE < <(${natpmpRequest} udp)
        echo "getting tcp"
        read -r TCPPORTPUBLIC TCPPORTPRIVATE < <(${natpmpRequest} tcp)
        {
          echo "UDPPORTPUBLIC=$UDPPORTPUBLIC"
          echo "UDPPORTPRIVATE=$UDPPORTPRIVATE"
          echo "TCPPORTPUBLIC=$TCPPORTPUBLIC"
          echo "TCPPORTPRIVATE=$TCPPORTPRIVATE"
        } > ${portsFile}
        chown rtorrent:rtorrent ${portsFile}
        ${applyNat}
      '';
      ExecStart = pkgs.writers.writeBash "keep-port-vpn" ''
        set -euo pipefail
        while true; do
          sleep 45
          source ${portsFile}
          read -r newUdpPublic newUdpPrivate < <(${natpmpRequest} udp)
          read -r newTcpPublic newTcpPrivate < <(${natpmpRequest} tcp)
          if [ "$newUdpPublic" != "$UDPPORTPUBLIC" ] || [ "$newTcpPublic" != "$TCPPORTPUBLIC" ]; then
            echo "natpmp public port changed (udp $UDPPORTPUBLIC -> $newUdpPublic, tcp $TCPPORTPUBLIC -> $newTcpPublic), reconfiguring"
            {
              echo "UDPPORTPUBLIC=$newUdpPublic"
              echo "UDPPORTPRIVATE=$newUdpPrivate"
              echo "TCPPORTPUBLIC=$newTcpPublic"
              echo "TCPPORTPRIVATE=$newTcpPrivate"
            } > ${portsFile}
            chown rtorrent:rtorrent ${portsFile}
            ${applyNat}
            ${pkgs.systemd}/bin/systemctl --no-block restart rtorrent.service
          fi
        done
      '';
      Type = "simple";
      Restart = "always";
    };
  };
}
