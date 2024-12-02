{ config, lib, pkgs, ... }:

let
  sway-run = pkgs.writeShellScriptBin "sway-run" (builtins.readFile ./sway-run.sh);
  gnome-wayland = pkgs.writeShellScriptBin "gnome-wayland" (builtins.readFile ./gnome-wayland.sh);
in {
  environment.systemPackages = [ gnome-wayland sway-run pkgs.gnome-session  pkgs.gnome-shell pkgs.gnome-shell-extensions pkgs.gnome-settings-daemon pkgs.gnome-control-center pkgs.gnome-common ];

  environment.etc."greetd/environments".text = ''
    sway-run
    gnome-wayland
    zsh
    bash
  '';
}
