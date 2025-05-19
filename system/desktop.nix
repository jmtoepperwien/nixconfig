{
  config,
  lib,
  modulesPath,
  inputs,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    tor-browser-bundle-bin
    pulsemixer

    # gnome icon themes (needed for some programs)
    adwaita-icon-theme

    # cisco anyconnect uni vpn
    openconnect
    networkmanager-openconnect

    qemu_kvm
    qemu-utils
    spice
    spice-protocol
    spice-gtk

    wlr-randr
    wl-mirror

    apptainer
    yubioath-flutter
    keepassxc
    libsecret
    yubikey-personalization
    yubikey-manager
    libfido2
    opensc
    pcsclite
  ];


  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      vhostUserPackages = [ pkgs.virtiofsd ];
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
           secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };
  programs.virt-manager.enable = true;

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

  users.groups.mtoepperwien = { };
  users.users.mtoepperwien = {
    isNormalUser = true;
    home = "/home/mtoepperwien";
    group = "mtoepperwien";
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "video"
      "audio"
      "render"
      "libvirtd"
      "adbusers"
    ];
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
  # enable nixos-enter into other architectures
  boot.binfmt.preferStaticEmulators = true;

  # Android ADB
  programs.adb.enable = true;

  # Allows for direct unicode printing
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [ anthy ];
  };

  hardware.yeetmouse = {
    enable = true;
    sensitivity = 1.0;
  };

  services.preload.enable = true;

  # Yubikey
  hardware.gpgSmartcards.enable = true;
  hardware.ledger.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.pcscd.enable = true;

  programs.spicetify =
  let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  in
  {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      hidePodcasts
      shuffle
      fullAlbumDate
    ];
    theme = spicePkgs.themes.onepunch;  # gruvbox
  };

  services.protonmail-bridge = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.protonmail-bridge;
  };
}
