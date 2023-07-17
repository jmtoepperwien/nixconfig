{ config, lib, modulesPath, pkgs, agenix, ... }:

{
  systemd.services."netns@" = {
    description = "%I network namespace";
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
      ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
    };
  };

  age.secrets.protonvpn = {
    file = ../secrets/protonvpn.age;
    owner = "root";
    group = "root";
  };
  systemd.services."protonvpn" = {
    description = "ProtonVPN in own network namespace";
    bindsTo = [ "netns@vpn.service" ];
    requires = [ "network-online.target" ];
    after = [ "netns@vpn.service" ];
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

  systemd.tmpfiles.rules = [ "d /etc/netns 0755 root root" "d /etc/netns/vpn 0755 root root" "f /etc/netns/vpn/resolv.conf 0644 root root"];
  environment.etc."netns/vpn/resolv.conf" = {
    text = ''
      nameserver 10.2.0.1
    '';
    mode = "0644";
  };

}
