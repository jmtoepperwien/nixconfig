{
  config,
  lib,
  pkgs,
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
    user = "rtorrent";
    group = "media";
    dataPermissions = "0775";
    downloadDir = "${config.server.media_folder}/downloads/torrent";
    configText = ''
      dht.mode.set = auto
      protocol.pex.set = yes

      trackers.use_udp.set = yes

      system.umask.set = 0002

      pieces.hash.on_completion.set = no

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

      schedule2 = watch_directory,1,30,"load.start_verbose=/var/lib/rtorrent/watch/*.torrent,d.directory.set=${config.server.media_folder}/downloads/torrent/,d.delete_tied="
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
      network.http.max_open.set = 99
      # Raised from 600: with 5k+ torrents and max_open_sockets=1024 the old
      # value left little headroom under LimitNOFILE=8192, causing fd
      # exhaustion stalls that manifest as RPC unresponsiveness.
      network.max_open_files.set = 4096
      network.max_open_sockets.set = 1024

      network.port_random.set = no

      # Peer settings
      throttle.min_peers.normal.set = 99
      throttle.max_peers.normal.set = 100
      throttle.min_peers.seed.set = -1
      throttle.max_peers.seed.set = -1
      throttle.max_downloads.global.set = 100
      throttle.max_uploads.global.set = 100
      throttle.max_downloads.set = 20
      throttle.max_uploads.set = 20
      trackers.numwant.set = 80
      ### performance
      network.receive_buffer.size.set =  16M
      network.send_buffer.size.set    = 16M

      # Miscellaneous settings
      pieces.memory.max.set = 2048M
      # First save 20 min after start, then every 12 h (wiki cadence for 5k+ torrents)
      schedule2 = session_save, 1200, 43200, ((session.save))
      system.file.allocate.set = 0
      pieces.preload.type.set = 2
      network.xmlrpc.size_limit.set = 4M

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
        "natpmp-forward.service"
      ];
      after = [
        "protonvpn.service"
        "natpmp-proton.service"
        "natpmp-forward.service"
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
        IOSchedulingPriority = 2;
        ExecStart = lib.mkForce (
          pkgs.writers.writeBash "start-rtorrent" ''
            echo "${config.services.rtorrent.package}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORTPUBLIC-$((TCPPORTPUBLIC+1)) -o dht.port.set=$UDPPORTPUBLIC"
            ${config.services.rtorrent.package}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORTPUBLIC-$((TCPPORTPUBLIC+1)) -o dht.port.set=$UDPPORTPUBLIC
          ''
        );
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
