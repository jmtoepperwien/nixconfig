{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.groups."kodi" = { };
  users.groups."video" = { };
  users.users."kodi" = {
    isNormalUser = true;
    group = "kodi";
    extraGroups = [
      "audio"
      "users"
      "wheel"
      "video"
      "render"
    ];
    home = "/var/lib/kodi";
    createHome = true;
  };

  environment.systemPackages = with pkgs; [
    kodi-gbm
    libcec
  ];

  systemd.sockets."kodi" = {
    wantedBy = [ "kodi" ];
    socketConfig = {
      ListenFIFO = "%t/kodi.stdin";
      Service = "kodi.service";
    };
  };
  systemd.services."kodi" = {
    enable = true;
    after = [
      "remote-fs.target"
      "systemd-user-sessions.service"
      "network-online.target"
      "nss-lookup.target"
      "sound.target"
      "polkit.service"
      "kodi.socket"
    ];
    wants = [
      "network-online.target"
      "polkit.service"
      "upower.service"
      "kodi.socket"
    ];
    conflicts = [ "getty@tty1.service" ];
    serviceConfig = {
      User = "kodi";
      Group = "kodi";
      Sockets = "kodi.socket";
      SupplementaryGroups = "input";
      ExecStart = "${pkgs.kodi-gbm}/bin/kodi-standalone";
      Restart = "on-abort";
      PAMName = "login";
      TTYPath = "/dev/tty1";
      StandardInput = "socket";
      StandardOutput = "journal";
    };
    aliases = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
  };

  networking.firewall.allowedTCPPorts = [ 8181 ];
  security.polkit.enable = true;
  services.dbus.enable = true;
}
