{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    ./hardware/maltepc.nix
    ../graphical/greetd.nix
  ];
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";
    useOSProber = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "maltepc";

  users.users.mtoepperwien = {
    isNormalUser = true;
    home = "/home/mtoepperwien";
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
