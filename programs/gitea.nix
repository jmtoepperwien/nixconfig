{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.users."gitea".extraGroups = [ "mysql" ];
  services.gitea = {
    enable = true;
    user = "gitea";
    settings = {
      server = {
        ROOT_URL = "https://mosigit.duckdns.org/";
        DOMAIN = "https://mosigit.duckdns.org/";
        HTTP_ADDR = "localhost";
        HTTP_PORT = 3000;
        SSH_PORT = 22;
      };
    };
    lfs = {
      enable = true;
    };
    database = {
      user = "gitea";
      name = "gitea";
      type = "postgres";
      socket = "/run/postgresql";
      createDatabase = false; # manually restore before this
    };
  };
}
