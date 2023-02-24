{ config, lib, pkgs, ... }:

{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "m.toepperwien@protonmail.com";
  security.acme.certs."mosihome.duckdns.org".extraDomainNames = [ "git.mosihome.duckdns.org" ];
  services.nginx = {
    enable = true;
    virtualHosts = {
      "mosihome.duckdns.org" = { # [TODO] nextcloud
        forceSSL = true;
        enableACME = true;
        sslCertificate = "..."; # [TODO]
        sslCertificateKey = "..."; # [TODO]
        enableACME = true;
        locations."/" = {
          root = "/var/www";
        };
      };
      "git.mosihome.duckdns.org" = {
        forceSSL = true;
        enableACME = true;
        useACMEHost = "mosihome.duckdns.org";
        sslCertificate = "..."; # [TODO]
        sslCertificateKey = "..."; # [TODO]
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
        };
      };
    };
  };
}
