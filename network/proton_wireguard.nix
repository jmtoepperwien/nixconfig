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
        source <(${pkgs.gawk} -F ' = ' '{if (! ($0 ~ /^[#\[]/)) print $0}' $conf | ${pkgs.gnused}/bin/sed 's/ = /=/g')

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
      ExecStop = pkgs.writers.writeBash "wg-down" ''
        ${pkgs.iproute2}/bin/ip -n vpn route del default dev wg0
        ${pkgs.iproute2}/bin/ip -n vpn link del wg0
      '';
    };
  };
}
