{ config, lib, pkgs, ... }:

let
  sway-run = pkgs.writeShellScriptBin "sway-run" (builtins.readFile ./sway-run.sh);
  gnome-wayland = pkgs.writeShellScriptBin "gnome-wayland" (builtins.readFile ./gnome-wayland.sh);
in {
  environment.systemPackages = [ gnome-wayland sway-run ];

  environment.etc."greetd/environments".text = ''
    sway-run
    gnome-wayland
    zsh
    bash
  '';
}
