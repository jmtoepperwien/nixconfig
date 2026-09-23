{ config, pkgs, ... }:
let
  autobrrPackage = pkgs.autobrr;
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
      path=${config.server.media_folder} # default, change as needed.
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
in
{
  systemd.tmpfiles.rules = [
    "d /var/lib/autobrr 0755 rtorrent rtorrent"
    "d /var/lib/autobrr/watch 0775 rtorrent rtorrent"
  ];

  age.secrets."autobrrConfig" = {
    file = ../../secrets/autobrrConfig.age;
    owner = "rtorrent";
    group = "rtorrent";
    path = "/var/lib/autobrr/config.toml";
  };

  systemd.services.autobrr = {
    after = [
      "flood.service"
      "network.target"
      "rtorrent.service"
    ];
    wants = [
      "flood.service"
      "rtorrent.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "rtorrent";
      Group = "media";
      WorkingDirectory = "/var/lib/autobrr";
      ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/rm -f /var/lib/autobrr/freespace.sh; ${pkgs.coreutils}/bin/cp ${autobrrFreeSpace}/bin/autobrr-free-space /var/lib/autobrr/freespace.sh'";
      ExecStart = "${autobrrPackage}/bin/autobrr --config=/var/lib/autobrr";
      Restart = "on-failure";
      Type = "simple";
    };
  };
}
