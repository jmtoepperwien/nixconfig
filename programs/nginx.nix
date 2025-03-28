{
  config,
  lib,
  pkgs,
  ...
}:

{
  systemd.tmpfiles.rules = [
    "d /var/www 0755 nginx nginx"
  ];
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "m.toepperwien@protonmail.com";
  security.acme.certs."mosihome.duckdns.org".extraDomainNames = [
    "mosigit.duckdns.org"
    "mosinextcloud.duckdns.org"
    "mosiseafile.duckdns.org"
  ];
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
          "/lidarr".proxyPass = "http://localhost:8686";
          "/readarr/".proxyPass = "http://localhost:8787";
          "/prowlarr/".proxyPass = "http://unix:/run/prowlarr/prowlarr.sock";
          "/navidrome".proxyPass = "http://localhost:3333";
          "/jellyfin/" = {
            proxyPass = "http://localhost:8096";
            extraConfig = ''
              rewrite ^/jellyfin/(.*) /$1 break;
            '';
          };
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
          "/grafana/" = {
            proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
            proxyWebsockets = true;
            recommendedProxySettings = true;
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
      "mosinextcloud.duckdns.org" = {
        forceSSL = true;
        useACMEHost = "mosihome.duckdns.org";
      };
      "mosiseafile.duckdns.org" = {
        forceSSL = true;
        useACMEHost = "mosihome.duckdns.org";
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
          "/sabnzbd/".proxyPass = "http://localhost:6789";
          "/sonarr/".proxyPass = "http://localhost:8989";
          "/radarr/".proxyPass = "http://localhost:7878";
          "/lidarr".proxyPass = "http://localhost:8686";
          "/readarr/".proxyPass = "http://localhost:8787";
          "/prowlarr/".proxyPass = "http://unix:/run/prowlarr/prowlarr.sock";
          "/navidrome".proxyPass = "http://localhost:3333";
          "/jellyfin/" = {
            proxyPass = "http://localhost:8096";
            extraConfig = ''
              rewrite ^/jellyfin/(.*) /$1 break;
            '';
          };
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
          "/tempfiles/" = {
            root = "/var/www";
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

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
