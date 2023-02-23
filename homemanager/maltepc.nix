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

  programs.zsh = {
    enable = true;
    enableCompletion = true; # not finished if system package completion is wanted (look at home manager documentation)
    autocd = true;
    defaultKeymap = "vicmd";
    history.save = 1000;
    history.size = 1000;
    initExtra = "setopt extended_glob\nbindkey 'kj' vi-cmd-mode";
    shellAliases = {
      "bat" = "bat --theme gruvbox-dark";
      "tree" = "tree -C";
      "tt" = "taskwarrior-tui";
      "cp" = "cp --reflink=auto";
    };
    prezto = {
      enable = true;
      editor = {
        dotExpansion = true;
        keymap = "vi";
      };
    };
  };
}
