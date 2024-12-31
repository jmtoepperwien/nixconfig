{ config, lib, modulesPath, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tor-browser-bundle-bin
    pulsemixer

    # gnome icon themes (needed for some programs)
    adwaita-icon-theme
    
    # cisco anyconnect uni vpn
    openconnect
    networkmanager-openconnect

    # secret management
    gnome-keyring
    libsecret

    qemu_kvm
    qemu-utils
    spice
    spice-protocol
    spice-gtk

    wlr-randr
    wl-mirror

    apptainer
  ];

  services.gnome.gnome-keyring.enable = true;

  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;

  services.fwupd.enable = true;
  hardware.enableRedistributableFirmware = true;

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    systemd-boot.enable = true;
  };
  networking.networkmanager.enable = true;

  users.groups.mtoepperwien = {};
  users.users.mtoepperwien = {
    isNormalUser = true;
    home = "/home/mtoepperwien";
    group = "mtoepperwien";
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "video" "audio" "render" "libvirtd" "adbusers" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [
      ../authorized_keys
    ];
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
    enableGnomeKeyring = true;
    text = ''
      auth     optional    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so
      session  optional    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start

      password  optional    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so
    '';
    gnupg.enable = true;
  };

  # containers with podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  programs.singularity = {
    enable = true;
  };

  # cross compilation
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Android ADB
  programs.adb.enable = true;
}
