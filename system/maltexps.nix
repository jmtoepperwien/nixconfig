{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    ./hardware/maltexps.nix
    ../graphical/greetd.nix
    ../graphical/environments-maltexps.nix
    ./desktop.nix
  ];

  services.tlp.enable = true;

  hardware.cpu.intel.updateMicrocode = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  nix.settings.max-jobs = 4;
  nix.settings.cores = 4;

  networking.hostName = "maltexps";

  # Gnome for touchscreen and beamer setups
  services.xserver.desktopManager.gnome = { # this should not be "xserver" but nix naming conventions are currently like this
    enable = true;
  };
  # disable this to use tlp as it seems to be better
  services.power-profiles-daemon.enable = false;
  # disable this to use pipewire instead
  hardware.pulseaudio.enable = false;

  system.stateVersion = "22.11";
}
