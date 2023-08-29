{ config, lib, modulesPath, pkgs, agenix, ... }:

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
        ${pkgs.iproute2}/bin/ip route add 169.254.251.2 dev brvpn0
        ${pkgs.iproute2}/bin/ip -n vpn route add 169.254.251.1 dev brvpn1

        ${pkgs.iproute2}/bin/ip -n vpn addr add 127.0.0.1/8 dev lo
        ${pkgs.iproute2}/bin/ip -n vpn link set lo up
        ${pkgs.iproute2}/bin/ip -n vpn route add 127.0.0.1 via dev lo
      '';
      ExecStop = pkgs.writers.writeBash "netns-withbridge-down" ''
        ${pkgs.iproute2}/bin/ip link del veth0
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
      ExecStart = pkgs.writers.writeBash "wg-up" ''
        conf=${config.age.secrets.protonvpn.path}
        source <(${pkgs.gawk}/bin/awk -F ' = ' '{if (! ($0 ~ /^[#\[]/)) print $0}' $conf | ${pkgs.gnused}/bin/sed 's/ = /=/g')

        # create wireguard interface; vpn namespace has to exist already
        ${pkgs.iproute2}/bin/ip link add wg0 type wireguard
        ${pkgs.iproute2}/bin/ip link set wg0 netns vpn

        ${pkgs.iproute2}/bin/ip -n vpn address add $Address dev wg0
        # conf without address and dns for wg setconf
        ${pkgs.iproute2}/bin/ip netns exec vpn \
          ${pkgs.wireguard-tools}/bin/wg setconf wg0 <(${pkgs.toybox}/bin/cat $conf | ${pkgs.gnused}/bin/sed -E '/^(DNS|Address).*/d')
        ${pkgs.iproute2}/bin/ip -n vpn link set wg0 up
        ${pkgs.iproute2}/bin/ip -n vpn route add default dev wg0
      '';
      ExecStartPost = pkgs.writers.writeBash "wait-online" ''
        until ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.unixtools.ping}/bin/ping -c1 www.google.com; do
	  echo "waiting for vpn to come online";
	done
      '';
      ExecStop = pkgs.writers.writeBash "wg-down" ''
        ${pkgs.iproute2}/bin/ip -n vpn route del default dev wg0
        ${pkgs.iproute2}/bin/ip -n vpn link del wg0
      '';
    };
  };
}
