{ config, pkgs, ... }:

{
  imports = [
    ./desktop.nix
  ];

  home.packages = with pkgs; [
    mattermost
  ];

  home.stateVersion = "25.05";
}
