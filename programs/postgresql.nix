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

  # Nightly logical backups onto the redundant zstorage pool (dataDir itself
  # stays on the fast NVMe zroot pool). Retention comes for free from the
  # existing sanoid schedule on zstorage/cloud (daily/monthly/yearly autoprune).
  systemd.tmpfiles.rules = [
    "d ${config.server.cloud_folder}/backups 0700 postgres postgres"
    "d ${config.server.cloud_folder}/backups/postgresql 0700 postgres postgres"
  ];
  services.postgresqlBackup = {
    enable = true;
    databases = [
      "nextcloud"
      "gitea"
      "lldap"
      "immich"
    ];
    location = "${config.server.cloud_folder}/backups/postgresql";
    compression = "zstd";
    startAt = "*-*-* 03:15:00";
  };
}
