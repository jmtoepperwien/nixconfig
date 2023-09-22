{ config, lib, pkgs, ... }:

{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "m.toepperwien@protonmail.com";
  security.acme.defaults.webroot = "/var/www/mosihome";
  security.acme.certs."mosihome.duckdns.org".extraDomainNames = [ "mosigit.duckdns.org" "mosinextcloud.duckdns.org" ];
  users.users.nginx.extraGroups = [ "rtorrent" ];
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    proxyTimeout = "30m";
    virtualHosts = {
      "mosihome.duckdns.org" = {
        forceSSL = true;
	enableACME = true;
	locations = {
	  "/files/" = {
	    root = "/var/www/";
	    extraConfig = ''
              access_log /var/log/nginx/public-files.log;
	      autoindex on;
	      proxy_max_temp_file_size 0;
	      aio threads;
	      directio 16M;
	      output_buffers 2 1M;
	      sendfile on;
	      sendfile_max_chunk 512k;
	    '';
	  };
          "/leander/" = {
	    root = "/var/www/";
	    extraConfig = ''
              disable_symlinks off;
              autoindex on;
              auth_basic           "Leander Serien";
              auth_basic_user_file /etc/nginx/.htpasswd;
              access_log /var/log/nginx/leander-files.log;
              proxy_max_temp_file_size 0;
              aio threads;
              directio 16M;
              output_buffers 2 1M;
              sendfile on;
              sendfile_max_chunk 1M;
              tcp_nopush on;
              tcp_nodelay on;
	    '';
	  };
	  "/sabnzbd/".proxyPass = "http://localhost:6789";
	  "/sonarr/".proxyPass = "http://localhost:8989";
	  "/radarr/".proxyPass = "http://localhost:7878";
          "/readarr/".proxyPass = "http://localhost:8787";
	  "/prowlarr/".proxyPass = "http://169.254.251.2:9696";
          "/autobrr/" = {
            proxyPass = "http://localhost:7474";
            extraConfig = ''
              rewrite ^/autobrr/(.*) /$1 break;
            '';
          };
          "/flood/" = {
            proxyPass = "http://localhost:5678";
            extraConfig = ''
              rewrite ^/flood/(.*) /$1 break;
            '';
          };
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
      "192.168.1.234" = {
        forceSSL = false;
        locations = {
          "/RPC2" = {
            extraConfig = ''
              include ${pkgs.nginx}/conf/scgi_params;
              scgi_pass unix:/run/rtorrent/rpc.sock;
            '';
          };
        };
      };
      "pi4.home.lan" = {
        forceSSL = false;
	locations = {
	  "/books/" = {
	    root = "/export/";
            extraConfig = ''
              disable_symlinks off;
	      allow 192.168.1.0/24;
	      deny all;
              autoindex on;
              proxy_max_temp_file_size 0;
              aio threads;
              directio 16M;
              output_buffers 2 1M;
              sendfile on;
              sendfile_max_chunk 1M;
              tcp_nopush on;
              tcp_nodelay on;
	    '';
	  };
          "/otherfiles/" = {
            root = "/export/";
            extraConfig = ''
              disable_symlinks off;
	      allow 192.168.1.0/24;
	      deny all;
              autoindex on;
              proxy_max_temp_file_size 0;
              aio threads;
              directio 16M;
              output_buffers 2 1M;
              sendfile on;
              sendfile_max_chunk 1M;
              tcp_nopush on;
              tcp_nodelay on;
            '';
          };
          "/RPC2" = {
            extraConfig = ''
              include ${pkgs.nginx}/conf/scgi_params;
              scgi_pass unix:/run/rtorrent/rpc.sock;
            '';
          };
	};
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
