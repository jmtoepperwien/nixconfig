{ config, lib, modulesPath, pkgs, ... }:

{
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "maltepc";
}
