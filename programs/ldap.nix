{
  config,
  lib,
  pkgs,
  ...
}:

{
  age.secrets.ldap = {
    file = ../secrets/ldap.age;
    owner = "lldap";
    group = "lldap";
  };
  users.groups."lldap" = {};
  users.users."lldap" = {
    isSystemUser = true;
    group = "lldap";
  };
  services.lldap = {
    enable = true;
    settings = {
      ldap_base_dn = "dc=example,dc=com";
      database_url = "postgres://%2Frun%2Fpostgresql/lldap";
    };
  };
}
