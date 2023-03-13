{ config, lib, pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" "gitea" ];
    ensureUsers = [
      {
        name = "nextcloud";
	ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
      }
      {
        name = "gitea";
	ensurePermissions."DATABASE gitea" = "ALL PRIVILEGES";
      }
    ];
  };
}
