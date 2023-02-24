{ config, lib, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    virtualHosts."git.mosihome.duckdns.org" = {
      forceSSL = true;
      sslCertificate = "..."; # [TODO]
      sslCertificateKey = "..."; # [TODO]
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
      };
    };
  };
}
