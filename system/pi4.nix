{ config, pkgs, lib, ... }:

{
 # This configuration worked on 09-03-2021 nixos-unstable @ commit 102eb68ceec
 # The image used https://hydra.nixos.org/build/134720986

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
    # ttyAMA0 is the serial console broken out to the GPIO
    kernelParams = [
        "8250.nr_uarts=1"
        "console=ttyAMA0,115200"
        "console=tty1"
        # A lot GUI programs need this, nearly all wayland applications
        "cma=128M"
    ];
  };

  #boot.loader.raspberryPi = {
  #  enable = true;
  #  version = 4;
  #};
  boot.loader.grub.enable = false;

  # Required for the Wireless firmware
  hardware.enableRedistributableFirmware = true;

  networking = {
    hostName = "pi4"; # Define your hostname.
    useDHCP = false;
    defaultGateway.address = "192.168.1.1";
    nameservers = [ "192.168.1.1" "1.1.1.1" "1.0.0.1" ];
    interfaces.wlan0.ipv4.addresses = [
      {
        address = "192.168.1.234";
        prefixLength = 24;
      }
    ];
  };
  age.secrets.wifipassword.file = ../secrets/wifipassword.age;
  networking.wireless = {
    environmentFile = config.age.secrets.wifipassword.path;
    enable = true;
    userControlled.enable = true;
    networks."Mosi".psk = "@MOSI_PASSWORD@";
  };

  users.users.pi4 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
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
