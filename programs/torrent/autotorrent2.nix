{
  config,
  pkgs,
  inputs,
  ...
}:
let
  autotorrent2Config = pkgs.writeText "at2config" ''
    [autotorrent]
    database_path = "/var/lib/rtorrent/autotorrent.db"
    link_type = "hard"
    always_verify_hash = [
        "*.nfo",
        "*.sfv",
        "*.diz",
    ]
    paths = [ "${config.server.media_folder}/downloads/torrent" ]
    same_paths = [ ]
    add_limit_size = 128_000_000
    add_limit_percent = 5
    store_path = "${config.server.media_folder}/downloads/torrent/{torrent_name}"
    skip_store_metadata = false
    cache_touched_files = false
    # rw_file_cache_chown = "1000:1000"
    rw_file_cache_ttl = 86400
    rw_file_cache_path = "${config.server.media_folder}/cache"
    # WARNING: setting fast_resume to true can cause errors and problems.
    fast_resume = true
    ignore_file_patterns = [ ]
    ignore_directory_patterns = [ ]

    [clients]

    [clients.rtorrent]
    display_name = "rtorrent"
    client_type = "rtorrent"
    url = "scgi:///run/rtorrent/rpc.sock"
    session_path = "/var/lib/rtorrent/session"
    label = "cross"
  '';
  autotorrent2Package = pkgs.callPackage ../autotorrent2.nix { };
in
{
  environment.systemPackages = [
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.recyclarr
    autotorrent2Package
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/rtorrent/at2-queue 0775 rtorrent rtorrent"
  ];

  #  systemd.timers.autotorrent2 = {
  #    wantedBy = [ "timers.target" ];
  #    timerConfig = {
  #      OnBootSec = "5m";
  #      OnUnitActiveSec = "5m";
  #      Unit = "autotorrent2.service";
  #    };
  #  };
  systemd.services.autotorrent2 = {
    requires = [
      "rtorrent.service"
    ];
    after = [
      "rtorrent.service"
    ];
    wantedBy = [ "multi-user.target" ];
    script =
      let
        at2AddScript = pkgs.writeShellScriptBin "at2-add-script" ''
          #!/bin/sh
          mkdir /var/lib/rtorrent/at2-queue/processed
          ${pkgs.inotify-tools}/bin/inotifywait --monitor --event create,moved_to,modify /var/lib/rtorrent/at2-queue \
          | while read changed; do
            # Coalesce bursts of events (e.g. cross-seed dropping several
            # matches at once) into a single pass instead of firing at2 once
            # per inotify event.
            sleep 5
            # First add catches torrents already indexed by a prior scan; scan
            # then refreshes the db with anything new on disk; second add
            # retries torrents that only match post-scan (e.g. content that
            # just finished writing when cross-seed dropped the file).
            ${autotorrent2Package}/bin/at2 --config ${autotorrent2Config} add rtorrent /var/lib/rtorrent/at2-queue/*.torrent
            ${autotorrent2Package}/bin/at2 --config ${autotorrent2Config} scan
            ${autotorrent2Package}/bin/at2 --config ${autotorrent2Config} add rtorrent /var/lib/rtorrent/at2-queue/*.torrent
            mv /var/lib/rtorrent/at2-queue/*.torrent /var/lib/rtorrent/at2-queue/processed
          done
        '';
      in
      "${at2AddScript}/bin/at2-add-script";
    serviceConfig = {
      User = "rtorrent";
      Group = "rtorrent";
      Type = "simple";
      Restart = "always";
    };
  };
}
