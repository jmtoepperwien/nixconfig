{ config, pkgs, lib, ... }:

{
 # This configuration worked on 09-03-2021 nixos-unstable @ commit 102eb68ceec
 # The image used https://hydra.nixos.org/build/134720986
  imports = [
    ./hardware/pi4.nix
  ];

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_rpi4;
    initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
    # ttyAMA0 is the serial console broken out to the GPIO
    kernelParams = [
        "8250.nr_uarts=1"
        "console=ttyAMA0,115200"
        "console=tty1"
        # A lot GUI programs need this, nearly all wayland applications
        "cma=512M"
    ];
  };

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.raspberryPi = {
    enable = false;
    version = 4;
    firmwareConfig = ''
      dtparam=audio=on
    '';
  };

  # Required for the Wireless firmware
  hardware.enableRedistributableFirmware = true;
  hardware.raspberry-pi."4" = {
    fkms-3d.enable = true;
    audio.enable = true;
    dwc2.enable = true;
  };
  #sound.enable = true;
  #hardware.pulseaudio.enable = true;
  hardware.opengl = {
    enable = true;
    setLdLibraryPath = true;
    package = pkgs.mesa_drivers;
  };
  # sound settings
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = false;
  };
  environment.systemPackages = [
    pkgs.pulsemixer
    pkgs.alsa-utils
    pkgs.libraspberrypi
  ];

  networking = {
    hostName = "pi4"; # Define your hostname.
    useDHCP = true;
    firewall.enable = false; # [TODO]
  };
  #age.secrets.wifipassword.file = ../secrets/wifipassword.age;
  #networking.wireless = {
  #  environmentFile = config.age.secrets.wifipassword.path;
  #  enable = true;
  #  userControlled.enable = true;
  #  networks."Mosi".psk = "@MOSI_PASSWORD@";
  #};

  users.users.pi4 = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" ];
    openssh.authorizedKeys.keyFiles = [
      ../authorized_keys
    ];
  };
  security.sudo.extraRules = [
    {
      users = [ "pi4" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];

  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
  };
  system.stateVersion = "22.11";
}
