{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.seafile = {
    enable = true;
    adminEmail = "m.toepperwien@protonmail.com";
    initialAdminPassword = "changethisseafilepassword";

    dataDir = "${config.server.cloud_folder}/seafile/data";

    ccnetSettings.General.SERVICE_URL = "https://mosiseafile.duckdns.org";
    seafileSettings = {
      history.keep_days = "14"; # Remove deleted files after 14 days
      fileserver = {
        host = "unix:/run/seafile/server.sock";
        web_token_expire_time = 18000; # Expire the token in 5h to allow longer uploads
      };
    };
    gc = {
      enable = true;
      dates = [ "Sun 03:00:00" ];
    };
  };

  services.nginx.virtualHosts."mosiseafile.duckdns.org" = {
    forceSSL = true;
    useACMEHost = "mosihome.duckdns.org";
    locations = {
      "/" = {
        proxyPass = "http://unix:/run/seahub/gunicorn.sock";
        extraConfig = ''
          proxy_read_timeout  1200s;
          client_max_body_size 0;
        '';
      };
      "/seafhttp" = {
        proxyPass = "http://unix:/run/seafile/server.sock";
        extraConfig = ''
          rewrite ^/seafhttp(.*)$ $1 break;
          client_max_body_size 0;
          proxy_connect_timeout  36000s;
          proxy_read_timeout  36000s;
          proxy_send_timeout  36000s;
          send_timeout  36000s;
        '';
      };
    };
  };
}
