{ config, lib, pkgs, ... }:
let
  sway-run = pkgs.writeShellScriptBin "sway-run" (builtins.readFile ./sway-run.sh);
  hyprland-run = pkgs.writeShellScriptBin "hyprland-run" (builtins.readFile ./hyprland-run.sh);
in {
  environment.systemPackages = [
    pkgs.greetd.greetd
    sway-run
    hyprland-run
  ]; 
  security.polkit.enable = true; # needed for seat management; couldn't get seatd to work
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.cage}/bin/cage -s -- ${pkgs.greetd.gtkgreet}/bin/gtkgreet";
      };
    };
  };
  programs.regreet.enable = true;
  environment.etc."greetd/environments".text = lib.mkDefault ''
    hyprland-run
    sway-run
    zsh
    bash
  '';
}
