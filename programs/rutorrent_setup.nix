{ config, lib, pkgs, ... }:
let
  app = "ruTorrent";
  domain = "pi4.home.lan";
  dataDir = "/var/www/rutorrent";
in {
  services.phpfpm.pools.${app} = {
    user = app;
    settings = {
      "listen.owner" = config.services.nginx.user;
      "pm" = "dynamic";
      "pm.max_children" = 32;
      "pm.max_requests" = 500;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 5;
      "php_admin_value[error_log]" = "stderr";
      "php_admin_flag[log_errors]" = true;
      "catch_workers_output" = true;
    };
    phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
  };
  services.nginx = {
    enable = true;
    virtualHosts.${domain} = {
      root = dataDir;
      listen = [ {
        addr = "0.0.0.0";
        port = 5678;
        ssl = false;
      } ];
      locations."/RPC2" = {
        extraConfig = ''
          scgi_pass unix:///run/rtorrent/rpc.sock;
          include ${pkgs.nginx}/conf/scgi_params;
          scgi_param SCRIPT_NAME /RPC2;
        '';
      };
      locations."~ [^/]\.php(/|$)" = {
        extraConfig = ''
          fastcgi_split_path_info ^(.+\.php)(/.+)$;
          fastcgi_pass unix:${config.services.phpfpm.pools.${app}.socket};
          include ${pkgs.nginx}/conf/fastcgi_params;
          include ${pkgs.nginx}/conf/fastcgi.conf;
          fastcgi_index  index.php;
          fastcgi_param SCRIPT_FILENAME $request_filename;
          fastcgi_read_timeout 300;
        '';
      };
    };
  };
  users.users.${app} = {
    isSystemUser = true;
    createHome = true;
    home = dataDir;
    group  = app;
    extraGroups = [ "rtorrent" ];
  };
  users.groups.${app} = {};

  networking.firewall.allowedTCPPorts = [ 5678 ];
}
