{ config, pkgs, ... }:

{
  home.username = "mtoepperwien";
  home.homeDirectory = "/home/mtoepperwien";
  home.stateVersion = "22.11";

  imports = [
    ./desktop.nix
    ./laptop.nix
  ];

  home.file.".config/sway/config" = {
    text = ''
      include maltexps
      include common
    '';
  };
}
