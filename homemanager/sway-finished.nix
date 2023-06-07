{ config, lib, pkgs, ... }:

{
  systemd.user.services."sway-finished.target" = {
    Unit = {
      Requires = [ "graphical-session.target" ];
      BindsTo = [ "graphical-session.target" ];
    };
  };
}
