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
        command = "cage gtkgreet";
      };
    };
  };
  environment.etc."greetd/environments".text = ''
    sway-run
    zsh
    bash
  '';
}
