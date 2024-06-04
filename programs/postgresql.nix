{ config, lib, pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" "gitea" ];
    ensureUsers = {
      nextcloud.name = "nextcloud";
      nextcloud.ensureDBOwnership = true;
      gitea.name = "gitea";
      gitea.ensureDBOwnership = true;
    };
  };
}
