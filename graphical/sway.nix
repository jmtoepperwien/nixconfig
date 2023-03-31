{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sway
    wayland
    wl-clipboard
  ];

  # xdg desktop portal for screensharing
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
