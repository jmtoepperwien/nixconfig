
{ config, lib, modulesPath, pkgs, agenix, nixpkgs, ... }:

{
  imports = [
    ./hardware/pi3.nix
  ];
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking = {
    hostName = "pi3";
    useDHCP = true;
    firewall.enable = false;
  };
  age.secrets.wifipassword.file = ../secrets/wifipassword.age;
  networking.wireless = {
    environmentFile = config.age.secrets.wifipassword.path;
    enable = true;
    userControlled.enable = true;
    networks = {
      Mosi24 = {
        psk = "@MOSI_PASSWORD@";
      };
    };
  };

  users.users.pi3 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with nixpkgs; [];
    openssh.authorizedKeys.keyFiles = [
      ../authorized_keys
    ];
  };
  security.sudo.extraRules = [
    {
      users = [ "pi3" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];

  system.stateVersion = "22.11";
}
