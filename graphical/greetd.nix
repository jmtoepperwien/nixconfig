{ config, lib, pkgs, ... }:
let
  sway-run = pkgs.writeShellScriptBin "sway-run" (builtins.readFile ./sway-run.sh);
in {
  environment.systemPackages = [
    pkgs.greetd.greetd
    pkgs.greetd.gtkgreet
    pkgs.cage
    sway-run
  ]; 
  security.polkit.enable = true; # needed for seat management; couldn't get seatd to work
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.dbus}/bin/dbus-run-session cage -s gtkgreet";
      };
    };
  };
  environment.etc."greetd/environments".text = lib.mkDefault ''
    sway-run
    zsh
    bash
  '';
}
