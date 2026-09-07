{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cross-seedHook = pkgs.writeShellScriptBin "cross-seed-hook" ''
    source ${config.age.secrets.cross-seed.path}
    ${pkgs.curl}/bin/curl -XPOST http://127.0.0.1:2468/api/webhook \
      -H "X-Api-Key: ''${apikey}" \
      --data-urlencode "infoHash=$1" \
      --data-urlencode 'includeSingleEpisodes=true'
  '';
  prunerrPackage = pkgs.callPackage ../prunerr.nix { };

  # Use rtorrent + libtorrent-rakshasa from nixpkgs-unstable (currently
  # 0.16.20). The earlier 0.16.15 pin was a workaround for 0.16.17's
  # CurlSocket lifecycle race (torrent::internal_error:
  # CurlSocket::event_error() self still exists), which crashed the
  # service ~20 min after start when session.save() held the main
  # thread and curl events queued up. That regression was fixed
  # upstream in 0.16.18 by commit 3b6da6fe ("Reordered http queue
  # slots to avoid race conditions.").
  #
  # Stable nixpkgs (nixos-26.05) ships rtorrent 0.16.5, which is too
  # old for the per-category socket API we rely on
  # (system.sockets.rpc.min_alloc).
  #
  # Note: 'libtorrent-rakshasa' is the rakshasa fork used by rtorrent;
  # there's a separate 'libtorrent-rasterbar' used by Deluge/qBittorrent
  # — do not confuse them. The upstream rtorrent derivation already
  # builds against the matching libtorrent-rakshasa from the same
  # nixpkgs-unstable, so no manual pairing is needed.
  rtorrentPackage = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.rtorrent;
in
{
  users.groups."rtorrent" = { };
  users.users."rtorrent" = {
    isSystemUser = lib.mkForce false;
    isNormalUser = lib.mkForce true;
    group = "media";
    extraGroups = [ "rtorrent" ];
  };

  environment.systemPackages = [
    pkgs.unrar
    prunerrPackage
  ];

  systemd.tmpfiles.rules = [
    "d ${config.server.media_folder}/downloads 0770 rtorrent media"
    "d ${config.server.media_folder}/downloads/torrent 0770 rtorrent media"
    "d /var/log/rtorrent 0770 rtorrent root"
  ];
  services.rtorrent = {
    enable = true;
    package = rtorrentPackage;
    user = "rtorrent";
    group = "media";
    dataPermissions = "0775";
    downloadDir = "${config.server.media_folder}/downloads/torrent";
    configText = lib.mkForce ''
      dht.mode.set = auto
      protocol.pex.set = yes

      trackers.use_udp.set = yes

      system.umask.set = 0002

      pieces.hash.on_completion.set = no

      # Default download dir (used by RPC/magnet adds; watch-dir schedule
      # overrides per-torrent below) and session path (matches
      # torrent-dir/link-dir in cross-seed.nix).
      # Restored from upstream nixpkgs module default config which we
      # are otherwise overriding via lib.mkForce above.
      directory.default.set = ${config.server.media_folder}/downloads/torrent
      session.path.set = /var/lib/rtorrent/session/

      ## The following line can be added to .rtorrent.rc to set up watch directories
      ##
      ## Replace:
      ##     [WATCH_DIR] with the directory to watch for torrent files
      ##     [DOWNLOAD_DIR] with the directory to save the files into
      ##     [LABEL] with a label to apply to torrents added via this watch dir
      ##        Important: Thus far i have not worked out how to use spaces in label names
      ##                   Do not include spaces for .torrent files will not be imported into rtorrent if you do
      ##
      ## Remove:
      ##     d.set_custom1=[LABEL] - to not add a label to the torrent
      ##     d.delete_tied= - to not delete the .torrent file after it has been added to rtorrent
      ##
      ## Notes:
      ##     When adding multiple watch directories ensure,
      ##     the string before the 1st comma is unique for all entries (watch_directory in example)
      ##     the number after the 1st comman is unique for all entries (1 in example)

      schedule = watch_directory,1,30,"load.start_verbose=/var/lib/rtorrent/watch/*.torrent,d.directory.set=${config.server.media_folder}/downloads/torrent/,d.delete_tied="
      ## set added time
      method.set_key = event.download.inserted_new, loaded_time, "d.custom.set=addtime,$cat=$system.time=;d.save_full_session="

      # enable flood
      method.redirect=load.throw,load.normal
      method.redirect=load.start_throw,load.start
      method.insert=d.down.sequential,value|const,0
      method.insert=d.down.sequential.set,value|const,0

      ## automatically execute cross-seed search on finished downloads
      method.set_key=event.download.finished,cross_seed,"execute2={${cross-seedHook}/bin/cross-seed-hook,$d.hash=}"

      # Network limits (tuned for 5k+ torrents; see programs/torrent commit msg)
      # RPC is its own socket category as of 0.16.15; raised above the
      # bracket default (48) to keep RPC responsive under peer/tracker
      # socket pressure from 5k+ torrents, independent of other categories.
      system.sockets.rpc.min_alloc.set = 64

      network.http.dns_cache_timeout.set = 25

      # Peer settings
      throttle.min_peers.normal.set = 99
      throttle.max_peers.normal.set = 100
      throttle.min_peers.seed.set = -1
      throttle.max_peers.seed.set = -1
      # Lowered from 100/100: fewer simultaneously-active torrents means
      # fewer concurrent random-read streams competing for disk I/O, which
      # was blocking rtorrent's single main thread and stalling RPC.
      throttle.max_downloads.global.set = 40
      throttle.max_uploads.global.set = 40
      throttle.max_downloads.set = 20
      throttle.max_uploads.set = 20
      trackers.numwant.set = 80
      ### performance
      network.receive_buffer.size.set =  16M
      network.send_buffer.size.set    = 16M

      # Miscellaneous settings
      pieces.memory.max.set = 2048M
      # First save 20 min after start, then every 12 h (wiki cadence for 5k+ torrents)
      schedule = session_save, 1200, 43200, ((session.save))
      # Stop new downloads when free space drops below 1 GB (5k+ torrents
      # can fill disk fast). Restored from upstream module default config.
      schedule = monitor_diskspace, 15, 60, ((close_low_diskspace, 1000M))
      system.file.allocate.set = 0
      # Disabled (was 2, "direct paging"): forces the main thread to
      # synchronously touch/page-in piece data before serving peers, which
      # blocks the same thread that services RPC on slow disk reads. Let
      # the kernel's normal async readahead handle it instead.
      pieces.preload.type.set = 0
      network.xmlrpc.size_limit.set = 4M

      # SCGI socket path. The upstream module's default config sets this
      # via `mkBefore`, but our configText uses `lib.mkForce` so we have
      # to set it explicitly. ExecStartPost (`fix-rpc-socket-permission`)
      # chmods g+w on this socket so the `media` group can scgi_pass it.
      scgi_local = /run/rtorrent/rpc.sock

      log.open_file = "debug_log", (cat,/var/log/rtorrent/debug_log.txt.,(system.time),.,(system.pid))
      log.add_output = "error", "debug_log"
      #log.add_output = "info", "debug_log"
      #log.add_output = "debug", "debug_log"
      #log.add_output = "tracker_debug", "debug_log"
    '';
  };

  systemd.services.rtorrent =
    let
      configFile = pkgs.writeText "rtorrent.rc" config.services.rtorrent.configText;
    in
    {
      bindsTo = [ "netns-vpn.service" ];
      requires = [
        "network-online.target"
        "protonvpn.service"
        "natpmp-proton.service"
      ];
      after = [
        "protonvpn.service"
        "natpmp-proton.service"
        "nss-lookup.target"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = "/run/proton_incoming";
        NetworkNamespacePath = "/var/run/netns/vpn";
        # Wiki explicit: implicit 4096 default must be overridden for >1024 sockets
        LimitNOFILE = "8192";
        # rtorrent's core is single-threaded; protect its scheduling latency
        # (and thus RPC responsiveness) from contention with nginx/ZFS/arr-suite.
        Nice = -5;
        IOSchedulingClass = "best-effort";
        # bfq now actually enforces this; keep rtorrent at the neutral
        # default so it doesn't outrank jellyfin's streaming reads.
        IOSchedulingPriority = 4;
        ExecStart = lib.mkForce (
          pkgs.writers.writeBash "start-rtorrent" ''
            echo "${config.services.rtorrent.package}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.listen.port.range.set=$TCPPORTPUBLIC-$TCPPORTPUBLIC -o dht.port.set=$UDPPORTPUBLIC"
            ${config.services.rtorrent.package}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.listen.port.range.set=$TCPPORTPUBLIC-$TCPPORTPUBLIC -o dht.port.set=$UDPPORTPUBLIC
          ''
        );
        # The module's own chmod/chown schedule (in its default configText)
        # is unreliable across rtorrent versions, silently leaving the
        # socket without group-write and breaking nginx's scgi_pass. Fix
        # it directly instead of depending on rtorrent's own scheduler.
        ExecStartPost = pkgs.writers.writeBash "fix-rpc-socket-permission" ''
          for i in $(seq 1 30); do
            if [ -S /run/rtorrent/rpc.sock ]; then
              chmod g+w /run/rtorrent/rpc.sock
              exit 0
            fi
            sleep 1
          done
          echo "rpc.sock did not appear within 30s" >&2
          exit 1
        '';
      };
    };

  # TCP→unix proxy so the *arr suite and autobrr can talk to rtorrent's SCGI
  # socket without going through nginx (whose `scgi_pass` against rtorrent
  # upstream was observed to be closed prematurely by rtorrent itself).
  # Mirrors the prowlarrforward pattern in programs/usenet.nix.
  systemd.services.rtorrent-scgi-tcp = {
    requires = [ "rtorrent.service" ];
    after = [ "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:5000,reuseaddr,fork,bind=127.0.0.1 UNIX-CONNECT:/run/rtorrent/rpc.sock";
      User = "rtorrent";
      Group = "media";
      Restart = "always";
      Type = "simple";
    };
  };
}
