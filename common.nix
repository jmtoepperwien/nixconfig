{ config, lib, modulesPath, pkgs, inputs, agenix, ... }:

{
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  imports = [
    ./common/devel.nix
  ];

  environment.systemPackages = with pkgs; [
    bat
    exa
    du-dust
    duf
    fzf
    fd
    ripgrep
    zoxide
    mcfly
    dig
    btrfs-progs
    wget
    curl
    glances
    hdparm
    mediainfo
    ncdu
    pass
    gnupg
    pinentry-curses
    tmux
    tree
    tealdeer
    unrar
    unzip
    unp
    sshfs
    zsh
    findutils
    smartmontools
    usbutils
    rename
    irssi
    wcalc
  ];

  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "curses";
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      nixgit = "cd /etc/nixos && sudo git pull";
    };
    autosuggestions.enable = true;
  };
  users.defaultUserShell = pkgs.zsh;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      user.name = "Jan Malte Töpperwien";
      user.email = "m.toepperwien@protonmail.com";
    };
  };
  xdg.mime.enable = true;

  # drive health checks
  services.smartd.enable = true;

  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  networking.networkmanager.dns = "none";
  networking.dhcpcd.extraConfig = "nohook resolv.conf";

  virtualisation = {
    oci-containers.backend = "podman";
    podman = {
      enable = true;

      dockerCompat = true;
    };
  };

  security.pki.certificateFiles = [ "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
}
