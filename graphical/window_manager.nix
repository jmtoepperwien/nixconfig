{
  config,
  lib,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    sway
    hyprland
    hyprpaper
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
    configPackages = [ pkgs.xdg-desktop-portal-wlr ];
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
