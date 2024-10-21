
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
    firewall.enable = true;
  };

  users.users.pi3 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with nixpkgs; [];
    openssh.authorizedKeys.keyFiles = [
      ../authorized_keys
    ];
  };

  environment.systemPackages = with pkgs; [ libraspberrypi ];

  system.stateVersion = "22.11";
}
