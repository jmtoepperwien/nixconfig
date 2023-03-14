{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    ./hardware/maltepc.nix
    ../graphical/greetd.nix
  ];

  services.fwupd.enable = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;

  # gpu
  hardware.opengl.enable = true;
  # vulkan
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [ 
    vulkan-tools
    vulkan-headers
    vulkan-loader
  ];

  nix.settings.max-jobs = 6;
  nix.settings.cores = 6;

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
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

  users.groups.mtoepperwien = {};
  users.users.mtoepperwien = {
    isNormalUser = true;
    home = "/home/mtoepperwien";
    group = "mtoepperwien";
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
  environment.systemPackages = [ pkgs.pulsemixer ];

  # cross compilation to aarch64
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # containers with podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };


  system.stateVersion = "22.11"; # Did you read the comment?
}
