{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    ./hardware/maltepc.nix
    ../graphical/greetd.nix
  ];

  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

  nix.settings.max-jobs = 6;
  nix.settings.cores = 6;

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    systemd-boot.enable = true;
  };

  networking.hostName = "maltepc";
  #age.secrets.wifipassword.file = ../secrets/wifipassword.age;
  #networking.wireless = {
  #  environmentFile = config.age.secrets.wifipassword.path;
  #  enable = true;
  #  userControlled.enable = true;
  #  networks.Mosi.psk = "@MOSI_PASSWORD@";
  #};
  networking.networkmanager.enable = true;

  users.users.mtoepperwien = {
    isNormalUser = true;
    home = "/home/mtoepperwien";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  # sound settings
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };


  system.stateVersion = "22.11"; # Did you read the comment?
}
