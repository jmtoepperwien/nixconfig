{
  config,
  lib,
  modulesPath,
  pkgs,
  agenix,
  ...
}:

let
  # WireGuard is silent until outbound traffic needs to go through the
  # interface, so a ping to the tunnel gateway is what actually triggers
  # the handshake; latest-handshakes then confirms it succeeded.
  waitHandshake = pkgs.writeShellScript "wg-wait-handshake" ''
    set -euo pipefail
    iface="$1"
    tries=60
    until [ "$(${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.wireguard-tools}/bin/wg show "$iface" latest-handshakes | ${pkgs.gawk}/bin/awk '{print $2}')" != "0" ]; do
      tries=$((tries - 1))
      if [ "$tries" -le 0 ]; then
        echo "timed out waiting for wireguard handshake" >&2
        exit 1
      fi
      echo "waiting for wireguard handshake"
      ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.unixtools.ping}/bin/ping -c1 -W1 10.2.0.1 >/dev/null 2>&1 || true
      sleep 1
    done
  '';
in

{
  systemd.services."netns-vpn" = {
    description = "vpn network namespace with bridge to normal network";
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writers.writeBash "netns-withbridge-up" ''
        ${pkgs.iproute2}/bin/ip netns add vpn
        ${pkgs.iproute2}/bin/ip link add brvpn0 type veth peer name brvpn1
        ${pkgs.iproute2}/bin/ip link set brvpn1 netns vpn
        ${pkgs.iproute2}/bin/ip addr add 169.254.251.1/16 dev brvpn0
        ${pkgs.iproute2}/bin/ip -n vpn addr add 169.254.251.2/16 dev brvpn1
        ${pkgs.iproute2}/bin/ip -n vpn link set brvpn1 up
        ${pkgs.iproute2}/bin/ip link set brvpn0 up
        ${pkgs.iproute2}/bin/ip route add 169.254.251.2 dev brvpn0
        ${pkgs.iproute2}/bin/ip -n vpn route add 169.254.251.1 dev brvpn1

        ${pkgs.iproute2}/bin/ip -n vpn addr add 127.0.0.1/8 dev lo
        ${pkgs.iproute2}/bin/ip -n vpn link set lo up
        ${pkgs.iproute2}/bin/ip -n vpn route add 127.0.0.1 via 127.0.0.1 dev lo
      '';
      ExecStop = pkgs.writers.writeBash "netns-withbridge-down" ''
        ${pkgs.iproute2}/bin/ip link del brvpn0
        ${pkgs.iproute2}/bin/ip netns del vpn
      '';
    };
  };

  age.secrets.protonvpn = {
    file = ../secrets/protonvpn.age;
    owner = "root";
    group = "root";
  };
  systemd.services."protonvpn" = {
    description = "ProtonVPN in own network namespace";
    bindsTo = [ "netns-vpn.service" ];
    requires = [ "network-online.target" ];
    after = [ "netns-vpn.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # ip netns exec bind-mounts /etc/netns/<name>/resolv.conf over
      # /etc/resolv.conf for anything run in that namespace.
      ExecStartPre = pkgs.writers.writeBash "wg-dns" ''
        set -euo pipefail
        conf=${config.age.secrets.protonvpn.path}

        install -d -m755 /etc/netns/vpn
        ${pkgs.gnugrep}/bin/grep -m1 -E '^DNS' "$conf" \
          | ${pkgs.gnused}/bin/sed -E 's/^DNS\s*=\s*//' \
          | tr ',' '\n' \
          | ${pkgs.gawk}/bin/awk '{print "nameserver " $1}' \
          > /etc/netns/vpn/resolv.conf
      '';
      # WireGuard's split-netns support keeps the interface's UDP
      # transport socket bound to whatever namespace it was created in,
      # while the plaintext side moves with `ip link set netns`; the
      # interface has to be created here in the host namespace first so
      # handshake packets can actually reach the internet. wg-quick
      # doesn't support taking over an already-created interface, so
      # this stays manual.
      ExecStart = pkgs.writers.writeBash "wg-up" ''
        set -euo pipefail
        conf=${config.age.secrets.protonvpn.path}

        # a previous failed start can leave a stale interface behind,
        # either already moved into the netns or still in the host ns
        ${pkgs.iproute2}/bin/ip -n vpn link del wg0 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link del wg0 2>/dev/null || true

        ${pkgs.iproute2}/bin/ip link add wg0 type wireguard
        ${pkgs.iproute2}/bin/ip link set wg0 netns vpn

        ${pkgs.gnugrep}/bin/grep -m1 -E '^Address' "$conf" \
          | ${pkgs.gnused}/bin/sed -E 's/^Address\s*=\s*//' \
          | tr ',' '\n' \
          | while read -r address; do
              ${pkgs.iproute2}/bin/ip -n vpn address add "$(echo "$address" | ${pkgs.gnused}/bin/sed -E 's/^\s+|\s+$//g')" dev wg0
            done
        ${pkgs.iproute2}/bin/ip netns exec vpn \
          ${pkgs.wireguard-tools}/bin/wg setconf wg0 <(${pkgs.gnugrep}/bin/grep -v -E '^(DNS|Address)' "$conf")
        ${pkgs.iproute2}/bin/ip -n vpn link set wg0 up
        ${pkgs.iproute2}/bin/ip -n vpn route add default dev wg0
      '';
      ExecStartPost = pkgs.writers.writeBash "wg-wait-online" ''
        set -euo pipefail
        ${waitHandshake} wg0
      '';
      ExecStop = pkgs.writers.writeBash "wg-down" ''
        set -euo pipefail
        ${pkgs.iproute2}/bin/ip -n vpn route del default dev wg0
        ${pkgs.iproute2}/bin/ip -n vpn link del wg0
        rm -rf /etc/netns/vpn
      '';
    };
  };
}
