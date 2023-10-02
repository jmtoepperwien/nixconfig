{ config, lib, pkgs, agenix, ... }:
{
  systemd.tmpfiles.rules = [ "d /mnt/kodi_lib/music 0755 pi4 usenet" ];
  services.navidrome = {
    enable = true;
    settings = {
      Address = "0.0.0.0";
      Port = "3333";
      MusicFolder = "/mnt/kodi_lib/music";
    };
  };
}
