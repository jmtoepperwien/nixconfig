{ config, lib, pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" "gitea" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
      {
        name = "gitea";
        ensureDBOwnership = true;
      }
    ];
  };
}
