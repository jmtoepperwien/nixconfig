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
  age.secrets.wifipassword.file = ../secrets/wifipassword.age;
  networking.wireless = {
    environmentFile = config.age.secrets.wifipassword.path;
    enable = true;
    userControlled.enable = true;
    networks.Mosi.psk = "@MOSI_PASSWORD@";
  };
  networking.networkmanager.enabled = true;

  users.users.mtoepperwien = {
    isNormalUser = true;
    home = "/home/mtoepperwien";
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
