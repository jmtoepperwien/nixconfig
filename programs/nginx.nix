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
        enableACME = true;
        locations."/" = {
          root = "/var/www/mosihome";
        };
      };
      "git.mosihome.duckdns.org" = {
        forceSSL = true;
        enableACME = true;
        useACMEHost = "mosihome.duckdns.org";
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
        };
      };
    };
  };
}
