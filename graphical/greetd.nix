{ config, lib, pkgs, ... }:
let
  sway-run = pkgs.writeShellScriptBin "sway-run" (builtins.readFile ./sway-run.sh);
  sway-greetd-config = pkgs.writeText "sway-greetd-config" ''
    exec "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l; swaymsg exit"
    bindsym Mod4+shift+e exec swaynag \
    -t warning \
    -m 'What do you want to do' \
    -b 'Poweroff' 'systemctl poweroff' \
    -b 'Reboot' 'systemctl reboot'

    include /etc/sway/config.d/*
  '';
in {
  environment.systemPackages = [
    pkgs.greetd.greetd
    sway-run
  ]; 
  security.polkit.enable = true; # needed for seat management; couldn't get seatd to work
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.sway}/bin/sway --config ${sway-greetd-config}";
      };
    };
  };
  programs.regreet.enable = true;
  environment.etc."greetd/environments".text = lib.mkDefault ''
    sway-run
    zsh
    bash
  '';
}
