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
    # extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # dont use this for now as it collides with gnome (different build configure options)
  };
}
