{ config, lib, pkgs, ... }:

{
  users.users.mysql = {
    description = "User for mysql server provided for local programs";
    isSystemUser = true;
    extraGroups = [ "mysql" ];
    home = "/home/mysql";
    createHome = true;
  };
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    user = "mysql";
    group = "mysql";
  };
}
