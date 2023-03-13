{ config, lib, pkgs, ... }:

{
  services.mysql = {
    enable = false;
    package = pkgs.mariadb;
    user = "mysql";
    group = "mysql";
  };
}
