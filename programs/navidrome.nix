{
  config,
  lib,
  pkgs,
  agenix,
  ...
}:
{
  systemd.tmpfiles.rules = [ "d ${config.server.media_folder}/music 0755 lidarr lidarr" ];
  services.navidrome = {
    enable = true;
    settings = {
      Address = "0.0.0.0";
      Port = 3333;
      MusicFolder = "${config.server.media_folder}/music";
      BaseUrl = "/navidrome";
    };
  };
}
