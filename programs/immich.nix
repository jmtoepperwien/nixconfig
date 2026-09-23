{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  systemd.tmpfiles.rules = [ "d ${config.server.media_folder}/immich 0750 immich immich" ];

  users.users.immich.extraGroups = [ "media" ];

  services.immich = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.immich;
    mediaLocation = "${config.server.media_folder}/immich";
    settings.server.externalDomain = "https://photos.mosi.me/";
  };
  services.nginx.virtualHosts."photos.mosi.me" = {
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };
}
