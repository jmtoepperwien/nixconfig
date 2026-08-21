{
  config,
  lib,
  pkgs,
  ...
}:

let
  hostName = "cloud.mosi.me";
  ldapBindEnvFile = "/run/ocis-secrets/ldap-bind.env";
in
{
  systemd.tmpfiles.rules = [
    "d ${config.server.cloud_folder}/ocis 0750 ${config.services.ocis.user} ${config.services.ocis.group}"
  ];

  users.users.${config.services.ocis.user}.extraGroups = [ "cloud" ];

  age.secrets."ocis-yaml" = {
    file = ../secrets/ocis-yaml.age;
    path = "${config.services.ocis.configDir}/ocis.yaml";
    owner = config.services.ocis.user;
    group = config.services.ocis.group;
  };
  age.secrets."ldap_bind_passwd_ocis" = {
    file = ../secrets/ldap_bind_passwd.age;
    owner = config.services.ocis.user;
    group = config.services.ocis.group;
  };

  # ldap_bind_passwd.age holds a bare password (shared with Seafile), but
  # services.ocis.environmentFile needs KEY=VALUE lines. Render that here
  # instead of duplicating the secret in oCIS-specific env-file format.
  systemd.services."ocis-ldap-env" = {
    description = "Generate oCIS LDAP bind password environment file";
    before = [ "ocis.service" ];
    wantedBy = [ "ocis.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = config.services.ocis.user;
      Group = config.services.ocis.group;
      RuntimeDirectory = "ocis-secrets";
      RuntimeDirectoryMode = "0750";
      ExecStart = pkgs.writeShellScript "ocis-ldap-env-setup" ''
        set -euo pipefail
        printf 'OCIS_LDAP_BIND_PASSWORD=%s\n' "$(cat ${config.age.secrets."ldap_bind_passwd_ocis".path})" > ${ldapBindEnvFile}
        chmod 0600 ${ldapBindEnvFile}
      '';
    };
  };

  services.ocis = {
    enable = true;
    address = "127.0.0.1";
    port = 9200;
    url = "https://${hostName}";
    configDir = "/etc/ocis";
    stateDir = "${config.server.cloud_folder}/ocis";
    environmentFile = ldapBindEnvFile;
    environment = {
      OCIS_URL = "https://${hostName}";
      OCIS_LOG_LEVEL = "info";
      PROXY_TLS = "false";
      OCIS_INSECURE = "false";
      PROXY_ENABLE_BASIC_AUTH = "true";

      # Disable the embedded LDAP server (idm) and use lldap instead.
      OCIS_EXCLUDE_RUN_SERVICES = "idm";
      OCIS_LDAP_URI = "ldap://127.0.0.1:3890";
      OCIS_LDAP_INSECURE = "true";
      OCIS_LDAP_BIND_DN = "uid=binduser,ou=people,dc=mosi,dc=com";

      # lldap user "crunchyflakes" entryUUID
      OCIS_ADMIN_USER_ID = "5945a640-ba40-3027-99b3-9332d6badc4c";

      LDAP_LOGIN_ATTRIBUTES = "uid";
      IDP_LDAP_LOGIN_ATTRIBUTE = "uid";
      IDP_LDAP_UUID_ATTRIBUTE = "entryuuid";
      OCIS_LDAP_USER_SCHEMA_ID = "entryuuid";
      OCIS_LDAP_GROUP_SCHEMA_ID = "uid";
      OCIS_LDAP_GROUP_SCHEMA_GROUPNAME = "uid";

      GRAPH_LDAP_SERVER_WRITE_ENABLED = "false";
      GRAPH_LDAP_REFINT_ENABLED = "false";

      OCIS_LDAP_GROUP_BASE_DN = "ou=groups,dc=mosi,dc=com";
      OCIS_LDAP_GROUP_OBJECTCLASS = "groupOfUniqueNames";
      OCIS_LDAP_GROUP_FILTER = "(objectclass=groupOfUniqueNames)";

      OCIS_LDAP_USER_BASE_DN = "ou=people,dc=mosi,dc=com";
      OCIS_LDAP_USER_OBJECTCLASS = "inetOrgPerson";
      OCIS_LDAP_USER_FILTER = "(&(objectclass=inetOrgPerson)(memberOf=cn=cloud,ou=groups,dc=mosi,dc=com))";
    };
  };

  services.nginx.virtualHosts.${hostName} = {
    forceSSL = true;
    useACMEHost = "mosi.me";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.ocis.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 0;
        proxy_buffering off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        send_timeout 600s;
      '';
    };
  };
}
