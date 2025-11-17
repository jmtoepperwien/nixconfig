{
  config,
  lib,
  pkgs,
  ...
}:

let
  gnome-wayland = pkgs.writeShellScriptBin "gnome-wayland" (builtins.readFile ./gnome-wayland.sh);
in
{
  environment.systemPackages = [
    gnome-wayland
    pkgs.gnome-session
    pkgs.gnome-shell
    pkgs.gnome-shell-extensions
    pkgs.gnome-settings-daemon
    pkgs.gnome-control-center
    pkgs.gnome-common
  ];

  environment.etc."greetd/environments".text = ''
    sway-run
    gnome-wayland
    zsh
    bash
  '';
}
