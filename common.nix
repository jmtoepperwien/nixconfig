{ config, lib, modulesPath, pkgs, agenix, ... }:

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
    wget
    curl
    ripgrep
    fd
    glances
    ncdu
    tmux
    tree
    tealdeer
    unzip
    unp
    zsh
    findutils
    smartmontools
    usbutils
  ];

  programs.zsh.enable = true;
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
}
