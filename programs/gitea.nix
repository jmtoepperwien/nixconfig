{ config, lib, pkgs, ... }:

{
  users.users.git = {
    description = "User for git and gitea";
    isSystemUser = true;
    extraGroups = [ "gitea" ];
    home = "/home/git";
    createHome = true;
  };
  age.secrets.mysqlpassword.file = ../secrets/pi4_mysql_password.age;
  service.gitea = {
    enable = true;
    user = git;
    repositoryRoot = "/home/git/gitea/repos";
    rootUrl = "http://localhost:3000/";
    httpPort = 3000;
    settings = {
      server = {
        SSH_PORT = 222;
      };
    };
    lfs = {
      enable = true;
      contentDir = "/home/git/gitea/lfs";
    };
    database ={
      user = "gitea";
      name = "gitea";
      type = "mysql";
      socket = "/var/run/mysqld.sock"
      passwordFile = config.age.secrets.mysqlpassword.path;
      createDatabase = false; # manually restore before this
    };
  };
}
