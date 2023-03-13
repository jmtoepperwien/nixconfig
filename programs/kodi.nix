{ config, lib, pkgs, ...}:

{
  users.groups."kodi" = {};
  users.groups."video" = {};
  users.users."kodi" = {
    isNormalUser = true;
    group = "kodi";
    extraGroups = [ "audio" "users" "wheel" "video" ];
    home = "/var/lib/kodi";
    createHome = true;
  };
  nixpkgs.overlays = [
    (self: super: { libcec = super.libcec.override { withLibraspberrypi = true; }; })
  ];

  environment.systemPackages = with pkgs; [
    kodi-gbm
    libcec
  ];


  systemd.services."kodi" = {
    enable = true;
    after = [ "remote-fs.target" "systemd-user-sessions.service" "network-online.target" "nss-lookup.target" "sound.target" "polkit.service" "upower.service" "mysqld.service" "getty@tty1.service" ];
    wants = [ "network-online.target" "polkit.service" "upower.service" ];
    conflicts = [ "getty@tty1.service" ];
    serviceConfig = {
      User = "kodi";
      Group = "kodi";
      SupplementaryGroups = "input";
      ExecStart = "${pkgs.kodi-gbm}/bin/kodi-standalone";
      Restart =  "on-abort";
      PAMName = "login";
      TTYPath = "/dev/tty1";
      StandardInput = "tty";
      StandardOutput = "journal";
    };
    aliases = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
  };

  services.udev.extraRules = ''
    # allow access to raspi cec device for video group (and optionally register it as a systemd device, used below)
    SUBSYSTEM=="vchiq", GROUP="video", MODE="0660", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/vchiq"
  '';

  # optional: attach a persisted cec-client to `/run/cec.fifo`, to avoid the CEC ~1s startup delay per command
  # scan for devices: `echo 'scan' &gt; /run/cec.fifo ; journalctl -u cec-client.service`
  # set pi as active source: `echo 'as' &gt; /run/cec.fifo`
  systemd.sockets."cec-client" = {
    after = [ "dev-vchiq.device" ];
    bindsTo = [ "dev-vchiq.device" ];
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenFIFO = "/run/cec.fifo";
      SocketGroup = "video";
      SocketMode = "0660";
    };
  };
  systemd.services."cec-client" = {
    after = [ "dev-vchiq.device" ];
    bindsTo = [ "dev-vchiq.device" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = ''${pkgs.libcec}/bin/cec-client -d 1'';
      ExecStop = ''/bin/sh -c "echo q &gt; /run/cec.fifo"'';
      StandardInput = "socket";
      StandardOutput = "journal";
      Restart="no";
    };
  };

  security.polkit.enable = true;
  services.dbus.enable = true;
}
