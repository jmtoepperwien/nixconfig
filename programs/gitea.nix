{ config, lib, pkgs, ... }:

{
  users.users."gitea".extraGroups = [ "mysql" ];
  services.gitea = {
    enable = true;
    user = "gitea";
    rootUrl = "https://mosigit.duckdns.org/";
    domain = "https://mosigit.duckdns.org/";
    httpAddress = "localhost";
    httpPort = 3000;
    settings = {
      server = {
        SSH_PORT = 22;
      };
    };
    lfs = {
      enable = true;
    };
    database ={
      user = "gitea";
      name = "gitea";
      type = "postgres";
      socket = "/run/postgresql";
      createDatabase = false; # manually restore before this
    };
  };
}
