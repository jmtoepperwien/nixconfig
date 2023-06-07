{ config, lib, pkgs, ... }:

{
  systemd.user.services."nextcloud" = {
    Unit = {
      Description = "Nextcloud Client";
      After = [ "sway-finished.service" ];
      PartOf = [ "sway-finished.target" ];
    };

    Service = {
      Type = "simple";
      StandardOutput = "journal";
      ExecStart = "env DISPLAY=':0' QT_QPA_PLATFORM=xcb ${pkgs.nextcloud-client}/bin/nextcloud --background";
    };
    
    Install = {
      WantedBy = [ "sway-finished.target" ];
    };
  };
}
