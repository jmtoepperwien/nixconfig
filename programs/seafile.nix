{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.groups.cloud = {};
  users.users.seafile.extraGroups = [ "cloud" ];
  systemd.tmpfiles.rules = [
    "d ${config.server.cloud_folder}/seafile 0750 seafile seafile"
    "d ${config.server.cloud_folder}/seafile/data 0750 seafile seafile"
  ];
  age.secrets.ldap_bind_passwd_seafile = {
    file = ../secrets/ldap_bind_passwd.age;
    owner = "seafile";
    group = "seafile";
  };
  services.seafile = {
    enable = true;
    adminEmail = "admin@local.com";
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
    seahubExtraConf = ''
      ENABLE_LDAP = True
      LDAP_SERVER_URL = "ldap://localhost:3890"
      LDAP_BASE_DN = "ou=people,dc=mosi,dc=com"
      LDAP_ADMIN_DN = "uid=binduser,ou=people,dc=mosi,dc=com"
      with open("${config.age.secrets.ldap_bind_passwd_seafile.path}", "r") as f:
          LDAP_ADMIN_PASSWORD = f.readline().rstrip()
      LDAP_PROVIDER = "ldap"
      LDAP_LOGIN_ATTR = "uid"
      LDAP_CONTACT_EMAIL_ATTR = "mail"
      LDAP_USER_ROLE_ATTR = ""
      LDAP_USER_FIRST_NAME_ATTR = "first_name"
      LDAP_USER_LAST_NAME_ATTR = "last_name"
      LDAP_USER_NAME_REVERSE = "False"
    '';
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
