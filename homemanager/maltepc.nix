{ config, pkgs, ... }:

{
  home.username = "mtoepperwien";
  home.homeDirectory = "/home/mtoepperwien";
  home.stateVersion = "23.05";

  home.packages = [
    pkgs.alacritty
    pkgs.mako
    pkgs.mpv
    pkgs.neovim
    pkgs.neovim-qt
    pkgs.qutebrowser
    pkgs.sway
    pkgs.waybar
    pkgs.zathura
  ];

  # use config folder
  home.file.".config" = {
    source = ./config;
    recursive = true;
  };
}
