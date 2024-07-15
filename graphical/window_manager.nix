{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sway
    hyprland
    wayland
    wl-clipboard
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # xdg desktop portal for screensharing
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default= "*"; # workaround, this should be set per interface (via xdg.portal.config or xdg.portal.configPackages)
  };
}
