{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "nextcloud"
      "gitea"
      "lldap"
      "immich"
    ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
      {
        name = "gitea";
        ensureDBOwnership = true;
      }
      {
        name = "lldap";
        ensureDBOwnership = true;
      }
      {
        name = "immich";
        ensureDBOwnership = true;
      }
    ];
    identMap = ''
      superuser_map root postgres
      superuser_map postgres postgres
      # Let other names login as themselves
      superuser_map /^(.*)$ \1
    '';
    authentication = pkgs.lib.mkOverride 10 ''
      local sameuser all peer map=superuser_map
      local all all trust
      host  all all 127.0.0.1/32 trust
      host  all all ::1/128      trust
    '';
  };
}
