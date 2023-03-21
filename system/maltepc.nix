{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    ./hardware/maltepc.nix
    ../graphical/greetd.nix
  ];
  environment.systemPackages = with pkgs; [
    tor-browser-bundle-bin
    pulsemixer
    
    # cisco anyconnect uni vpn
    openconnect
    networkmanager-openconnect

    # secret management
    gnome.gnome-keyring
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

  # secret management
  security.pam.services."gnome_keyring" = {
    text = ''
      auth     optional    ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so
      session  optional    ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start

      password  optional    ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so
    '';
  };

  # cross compilation to aarch64
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # containers with podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };


  system.stateVersion = "22.11"; # Did you read the comment?
}
