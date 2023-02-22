{ config, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.seatd
    pkgs.greetd.greetd
    pkgs.greetd.gtkgreet
  ]; 
  services.greetd.enable = true;
}
