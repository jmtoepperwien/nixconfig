{ config, lib, pkgs, inputs, agenix, ... }:
let
  media_folder = "/mnt/media";
  rtorrentPackage = pkgs.callPackage ./rtorrent/default.nix { libtorrent = pkgs.callPackage ./rtorrent/libtorrent.nix {}; };
  cross-seedPackage = pkgs.callPackage ./cross-seed.nix {};
  cross-seedHook = pkgs.writeShellScriptBin "cross-seed-hook" ''
    echo "searching for" >> /var/lib/rtorrent/scriptlog.txt
    echo $1 >> /var/lib/rtorrent/scriptlog.txt
    ${pkgs.curl}/bin/curl -XPOST http://127.0.0.1:2468/api/webhook --data-urlencode "name=$1"
    echo "searched for" >> /var/lib/rtorrent/scriptlog.txt
    echo $1 >> /var/lib/rtorrent/scriptlog.txt
  '';
  autotorrent2Package = pkgs.callPackage ./autotorrent2.nix {};
  prunerrPackage = pkgs.callPackage ./prunerr.nix {};
  autobrrPackage = pkgs.callPackage ./autobrr.nix {};
  autobrrFreeSpace = pkgs.writeShellScriptBin "autobrr-free-space" ''
    #!/bin/sh
    set -e
    
    # argument 1: torrent payload size; bytes.
    if ! [[ "$1" =~ ^[0-9]*$ ]]; then
      exit 5 # invalid 'size' argument.
    fi
    if [[ $(($1)) -gt 0 ]]; then
      if [[ $1 -gt 102400 ]]; then
        size=$(($1/1024))
      else # if the size is too small it may not be for the payload.
        size=$((5*1024*1024)) # use larger size.
      fi
    else
      size=0 # ignore torrent size.
    fi
    
    # argument 2: space to keep free; GiB, integer.
    if ! [[ "$2" =~ ^[0-9]*$ ]]; then
      exit 4 # invalid 'keep' argument.
    fi
    if [[ $(($2)) -gt 0 ]]; then
      keep=$2
    else
      keep=100 # default, change as needed.
    fi
    
    # argument 3: torrent save path.
    if [[ -z "$3" ]]; then
      path=${media_folder} # default, change as needed.
    else
      path=$3
    fi
    if ! [[ -d "$path" ]]; then
      exit 3 # invalid 'path' argument.
    fi
    
    # get free space available.
    have=$((`${pkgs.busybox}/bin/df "$path" | ${pkgs.busybox}/bin/awk 'END{print $4}'`))
    
    # get minimum free space required.
    need=$((($keep*1024*1024)+$size))
    
    # check if the needed free space is available.
    if [[ $have -eq 0 ]]; then
      exit 2 # no free space.
    elif [[ $have -lt $need ]]; then
      exit 1 # not enough free space.
    else
      exit 0 # free space available.
    fi
  '';
in {
  users.groups."rtorrent" = {};
  users.users."rtorrent" = {
    isSystemUser = lib.mkForce false;
    isNormalUser = lib.mkForce true;
    group = "usenet";
    extraGroups= [ "rtorrent" ];
  };

  environment.systemPackages = [ inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.flood pkgs.unpackerr inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.recyclarr cross-seedPackage pkgs.unrar autotorrent2Package prunerrPackage ]; # broken dependencies: pkgs.torrenttools pkgs.mktorrent 

  systemd.tmpfiles.rules = [
    "d ${media_folder}/downloads 0770 rtorrent usenet"
    "d ${media_folder}/downloads/torrent 0770 rtorrent usenet"
    "d /var/lib/autobrr 0755 rtorrent rtorrent"
    "d /var/lib/autobrr/watch 0775 rtorrent rtorrent"
    "d /var/lib/cross-seed 0755 rtorrent rtorrent"
    "d /var/lib/cross-seed/watch 0775 rtorrent rtorrent"
    "d /var/lib/rtorrent/at2-queue 0775 rtorrent rtorrent"
    "d /var/log/rtorrent 0770 rtorrent root"
  ];
  services.rtorrent = {
    enable = true;
    package = pkgs.jesec-rtorrent;
    user = "rtorrent";
    group = "usenet";
    dataPermissions = "0775";
    downloadDir = "${media_folder}/downloads/torrent";
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

      #schedule2 = watch_directory,1,5,"load.start_verbose=/var/lib/autobrr/watch/*.torrent,d.directory.set=/mnt/kodi_lib/downloads_torrent/,d.delete_tied=,d.custom1.set=autobrr"
      ## set added time
      method.set_key = event.download.inserted_new, loaded_time, "d.custom.set=addtime,$cat=$system.time=;d.save_full_session="

      ## automatically execute cross-seed search on finished downloads
      method.set_key=event.download.finished,cross_seed,"execute2={${cross-seedHook}/bin/cross-seed-hook,$d.name=}"

      ### performance
      # Network limits
      network.http.max_open.set = 50
      #network.max_open_files.set = 600
      network.max_open_sockets.set = 200

      # Peer settings
      throttle.min_peers.normal.set = 39
      throttle.max_peers.normal.set = 40
      throttle.min_peers.seed.set = -1
      throttle.max_peers.seed.set = -1
      throttle.max_downloads.global.set = 100
      throttle.max_uploads.global.set = 100
      throttle.max_downloads.set = 20
      throttle.max_uploads.set = 20
      trackers.numwant.set = 40

      # Miscellaneous settings
      pieces.memory.max.set = 2000M
      schedule2 = session_save, 240, 300, ((session.save))
      system.file.allocate.set = 1
      pieces.preload.type.set = 2
      network.xmlrpc.size_limit.set = 2M

      log.open_file = "debug_log", (cat,/var/log/rtorrent/debug_log.txt.,(system.time).,(system.pid))
      log.add_output = "error", "debug_log"
      #log.add_output = "info", "debug_log"
      #log.add_output = "debug", "debug_log"
      #log.add_output = "tracker_debug", "debug_log"
    '';
  };

  systemd.services."natpmp-proton" = {
    enable = true;
    description = "Acquire incoming port from protonvpn natpmp";
    requires = [ "protonvpn.service" ];
    after = [ "protonvpn.service" ];
    bindsTo = [ "protonvpn.service" ];
    serviceConfig = {
      TimeoutSec = 60;
      User = "root";
      NetworkNamespacePath = "/var/run/netns/vpn";
      # [TODO: not hardcoded gateway]
      ExecStartPre = pkgs.writers.writeBash "acquire-port-vpn" ''
        echo "getting udp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 udp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*Mapped public port ([0-9]+) .* to local port ([0-9]+) .*/UDPPORTPUBLIC=\1\nUDPPORTPRIVATE=\2/' > /run/proton_incoming"
        echo "getting tcp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 udp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*Mapped public port ([0-9]+) .* to local port ([0-9]+) .*/TCPPORTPUBLIC=\1\nTCPPORTPRIVATE=\2/' >> /run/proton_incoming" && chown rtorrent:rtorrent /run/proton_incoming
      '';
      ExecStart = pkgs.writers.writeBash "keep-port-vpn" ''
       echo "looping to keep"
        while true ; do
          ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 udp 60 && ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 tcp 60
          sleep 45
        done
      '';
      Type = "simple";
      Restart = "always";
    };
  };

  systemd.services."natpmp-forward" = {
    enable = true;
    description = "Port forward natpmp open port so that public port matches private port";
    requires = [ "natpmp-proton.service" ];
    after = [ "natpmp-proton.service" ];
    bindsTo = [ "natpmp-proton.service" ];
    serviceConfig = {
      EnvironmentFile = "/run/proton_incoming";
      User = "root";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = pkgs.writers.writeBash "forward-port-vpn-tcp" ''
        echo "forwarding TCP $TCPPORTPRIVATE to $TCPPORTPUBLIC and UDP $UDPPORTPRIVATE to $UDPPORTPUBLIC"
        ${pkgs.nftables}/bin/nft add table ip nat
        ${pkgs.nftables}/bin/nft -- add chain ip nat prerouting { type nat hook prerouting priority -100 \; }
        ${pkgs.nftables}/bin/nft add rule ip nat prerouting tcp dport $TCPPORTPRIVATE redirect to :$TCPPORTPUBLIC
        ${pkgs.nftables}/bin/nft add rule ip nat prerouting udp dport $UDPPORTPRIVATE redirect to :$UDPPORTPUBLIC
      '';
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
  };

  systemd.services.rtorrent = let
    configFile = pkgs.writeText "rtorrent.rc" config.services.rtorrent.configText;
    rtorrentPackage = config.services.rtorrent.package;
  in {
    bindsTo = [ "netns-vpn.service" ];
    requires = [ "network-online.target" "protonvpn.service" "natpmp-proton.service" "natpmp-forward.service" ];
    after = [ "protonvpn.service" "natpmp-proton.service" "natpmp-forward.service" "nss-lookup.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      EnvironmentFile = "/run/proton_incoming";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = lib.mkForce (pkgs.writers.writeBash "start-rtorrent" ''
        echo "${rtorrentPackage}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORTPUBLIC-$TCPPORTPUBLIC -o dht.port.set=$UDPPORTPUBLIC
"
        ${rtorrentPackage}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORTPUBLIC-$((TCPPORTPUBLIC+1)) -o dht.port.set=$UDPPORTPUBLIC
      '');
    };
  };

  services.rutorrent = {
    enable = false;
    group = "rtorrent";
    hostName = "0.0.0.0";
    nginx.enable = true;
  };

  systemd.services.flood = {
    enable = true;
    description = "Flood frontend for rtorrent";
    bindsTo = [ "rtorrent.service" ];
    after = [ "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.flood}/bin/flood --rtsocket /run/rtorrent/rpc.sock --port 5678 --host 0.0.0.0";
      Restart = "on-failure";
      Type = "simple";
      User = "rtorrent";
      Group = "rtorrent";
    };
  };
  networking.firewall.allowedTCPPorts = [ 5678 5656 ];

  users.groups."unpackerr" = {};
  users.users."unpackerr" = {
    isSystemUser = true;
    group = "unpackerr";
    extraGroups = [ "rtorrent" "usenet" ];
  };

  age.secrets.unpackerrConfig = {
    file = ../secrets/unpackerrConfig.age;
    owner = "unpackerr";
    group = "unpackerr";
  };

  systemd.services.unpackerr = {
    after = [ "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "unpackerr";
      Group = "usenet";
      ExecStart = "${pkgs.unpackerr}/bin/unpackerr --config=${config.age.secrets.unpackerrConfig.path}";
      Type = "simple";
    };
  };


  age.secrets."autobrrConfig" = {
    file = ../secrets/autobrrConfig.age;
    owner = "rtorrent";
    group = "rtorrent";
    path = "/var/lib/autobrr/config.toml";
  };

  systemd.services.autobrr = {
    after = [ "flood.service" "network.target" "rtorrent.service" ];
    requires = [ "flood.service" "rtorrent.service" "autotorrent2.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "rtorrent";
      Group = "usenet";
      WorkingDirectory = "/var/lib/autobrr";
      ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/rm -f /var/lib/autobrr/freespace.sh; ${pkgs.coreutils}/bin/cp ${autobrrFreeSpace}/bin/autobrr-free-space /var/lib/autobrr/freespace.sh'";
      ExecStart = "${autobrrPackage}/bin/autobrr --config=/var/lib/autobrr";
      Type = "simple";
    };
  };


  systemd.services.cross-seed = let
    trackers = "http://127.0.0.1:9696/17/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/26/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/8/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/21/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/19/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/18/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/23/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/13/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/27/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/13/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/30/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/31/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/32/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/33/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/34/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/35/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/36/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/38/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/39/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/40/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/41/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/42/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/43/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/44/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/46/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535 http://127.0.0.1:9696/47/api?apikey=3e3fcaccc58e414ca7fe8b76c4da0535";
    search-cadence = "2w";
    rss-cadence = "30min";
    delay = "60";
    snatch-timeout = "5min";
    search-timeout = "5min";
    torrent-dir = "/var/lib/rtorrent/session";
    output-dir = "/var/lib/rtorrent/at2-queue";
    fuzzy-thr = "0.1";
  in {
    after = [ "rtorrent.service" ];
    requires = [ "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "rtorrent";
      Group = "rtorrent";
      WorkingDirectory = "/var/lib/cross-seed";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = "${cross-seedPackage}/bin/cross-seed daemon --torznab ${trackers} --search-cadence ${search-cadence} --rss-cadence ${rss-cadence} --delay ${delay} --snatch-timeout ${snatch-timeout} --search-timeout ${search-timeout} --torrent-dir ${torrent-dir} --output-dir ${output-dir} --include-episodes --include-non-videos --action save --match-mode risky --verbose --fuzzy-size-threshold ${fuzzy-thr}";
      Restart = "always";
    };
  };

#  systemd.timers.autotorrent2 = {
#    wantedBy = [ "timers.target" ];
#    timerConfig = {
#      OnBootSec = "5m";
#      OnUnitActiveSec = "5m";
#      Unit = "autotorrent2.service";
#    };
#  };
  systemd.services.autotorrent2 = {
    requires = [ "rtorrent.service" "rtorrent.service" ];
    after = [ "rtorrent.service" "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    script = let
      at2AddScript = pkgs.writeShellScriptBin "at2-add-script" ''
        #!/bin/sh
        mkdir /var/lib/rtorrent/at2-queue/processed
        ${pkgs.inotify-tools}/bin/inotifywait --monitor --event create,moved_to,modify /var/lib/rtorrent/at2-queue \
        | while read changed; do
          ${autotorrent2Package}/bin/at2 add rtorrent /var/lib/rtorrent/at2-queue/*.torrent
          ${autotorrent2Package}/bin/at2 scan
          ${autotorrent2Package}/bin/at2 add rtorrent /var/lib/rtorrent/at2-queue/*.torrent
          for file in /var/lib/rtorrent/at2-queue/*.torrent; do
            ${autotorrent2Package}/bin/at2 add rtorrent "$file"
            mv "$file" /var/lib/rtorrent/at2-queue/processed
          done
        done
      '';
    in "${at2AddScript}/bin/at2-add-script";
    serviceConfig = {
      User = "rtorrent";
      Group = "rtorrent";
      Type = "simple";
      Restart = "always";
    };
  };
}
