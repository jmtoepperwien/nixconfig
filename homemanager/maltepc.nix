{ config, pkgs, ... }:

{
  home.username = "mtoepperwien";
  home.homeDirectory = "/home/mtoepperwien";
  home.stateVersion = "23.05";

  # sway
  home.file.".config/sway/config".source = ./maltepc/sway/config;
}
