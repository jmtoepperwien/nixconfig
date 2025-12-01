{
  config,
  lib,
  modulesPath,
  pkgs,
  inputs,
  agenix,
  ...
}:

{
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];
  networking.networkmanager.dns = "none";
  networking.dhcpcd.extraConfig = "nohook resolv.conf";
}
