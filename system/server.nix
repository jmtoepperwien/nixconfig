{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware/server_disko.nix
  ];

  boot = {
    kernel.sysctl = {
      # networking tweaks (bigger buffers)
      "net.core.rmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 12582912 16777216";
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_wmem" = "4096 12582912 16777216";
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.ipv4.tcp_tw_recycle" = 1;
      "net.ipv4.tcp_fin_timeout" = 30;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  #sound.enable = true;
  #hardware.pulseaudio.enable = true;
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
    pkgs.mediainfo
    pkgs.mergerfs
    pkgs.mergerfs-tools
    pkgs.fuse
  ];

  networking = {
    hostName = "server"; # Define your hostname.
    useDHCP = true;
    firewall.enable = true;
    nftables.enable = true;
    firewall.allowedTCPPorts = [ 53589 ];
  };

  users.users.mtoepperwien = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "usenet" "rtorrent" ];
    openssh.authorizedKeys.keyFiles = [
      ../authorized_keys
    ];
  };

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
  system.stateVersion = "24.11";
}
