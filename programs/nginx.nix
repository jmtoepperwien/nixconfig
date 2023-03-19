{ config, lib, pkgs, ... }:

{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "m.toepperwien@protonmail.com";
  security.acme.defaults.webroot = "/var/www/mosihome";
  security.acme.certs."mosihome.duckdns.org".extraDomainNames = [ "mosigit.duckdns.org" "mosinextcloud.duckdns.org" ];
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "mosihome.duckdns.org" = {
        forceSSL = true;
	enableACME = true;
	locations = {
	  "/files/" = {
	    root = "/var/www/";
	    extraConfig = ''
              access_log off;
	      autoindex on;
	      proxy_max_temp_file_size 0;
	      aio threads;
	      directio 16M;
	      output_buffers 2 1M;
	      sendfile on;
	      sendfile_max_chunk 512k;
	    '';
	  };
	  "/sabnzbd/".proxyPass = "http://localhost:6789";
	  "/sonarr/".proxyPass = "http://localhost:8989";
	  "/radarr/".proxyPass = "http://localhost:7878";
	  "/prowlarr/".proxyPass = "http://localhost:9696";
	};
      };
      "mosigit.duckdns.org" = {
        forceSSL = true;
	useACMEHost = "mosihome.duckdns.org";
        locations = {
          "/" = {
            proxyPass = "http://localhost:3000/";
          };
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
