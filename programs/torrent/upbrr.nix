{ config, pkgs, ... }:
let
  upbrrPackage = pkgs.upbrr;

  # Static, non-secret configuration generated at build time and symlinked
  # into /var/lib/upbrr/ by systemd-tmpfiles. Only web-auth.json (the
  # password hash + encryption-key seed) is an agenix secret.
  upbrrConfigFile = pkgs.writeText "upbrr-config.yaml" ''
    main_settings:
      db_path: /var/lib/upbrr/db.sqlite
  '';
  upbrrWebConfigFile = pkgs.writeText "upbrr-web-config.json" (builtins.toJSON {
    host = "127.0.0.1";
    port = 7480;
    base_url = "https://mosi.me/upbrr/";
    trusted_proxies = [ "127.0.0.1" ];
    session_ttl = 1440;
    open_browser = false;
  });
in
{
  users.groups."upbrr" = { };
  users.users."upbrr" = {
    isSystemUser = true;
    group = "upbrr";
    extraGroups = [ "media" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/upbrr 0755 upbrr upbrr"
    # Symlink the static config files from the Nix store into the state dir.
    # The symlink lives in /var/lib/upbrr (upbrr:upbrr) and points to a
    # /nix/store path (root-owned, mode 0444), which upbrr can read.
    "L /var/lib/upbrr/config.yaml - - - - ${upbrrConfigFile}"
    "L /var/lib/upbrr/web-config.json - - - - ${upbrrWebConfigFile}"
  ];

  age.secrets."upbrrWebAuth" = {
    file = ../../secrets/upbrrWebAuth.age;
    owner = "upbrr";
    group = "upbrr";
    path = "/var/lib/upbrr/web-auth.json";
    mode = "0600";
  };

  environment.systemPackages = [
    pkgs.ffmpeg
  ];

  systemd.services.upbrr = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "upbrr";
      Group = "upbrr";
      WorkingDirectory = "/var/lib/upbrr";
      ExecStart = "${upbrrPackage}/bin/upbrr serve --config=/var/lib/upbrr";
      Type = "simple";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      ReadWritePaths = "/var/lib/upbrr";
    };
  };
}
