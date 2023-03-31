{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sway
    wayland
    wl-clipboard
  ];
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # enable sway window manager
  programs.sway = {
    enable = true;
  };
}
