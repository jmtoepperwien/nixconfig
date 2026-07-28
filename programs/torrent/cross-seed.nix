{ config, pkgs, ... }:
let
  search-cadence = "2w";
  rss-cadence = "30min";
  delay = "60";
  snatch-timeout = "5min";
  search-timeout = "5min";
  torrent-dir = "/var/lib/rtorrent/session";
  output-dir = "/var/lib/rtorrent/at2-queue";
  fuzzy-thr = "0.1";
in
{
  environment.systemPackages = [
    pkgs.cross-seed
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/cross-seed 0755 rtorrent rtorrent"
    "d /var/lib/cross-seed/watch 0775 rtorrent rtorrent"
  ];

  age.secrets.cross-seed = {
    file = ../../secrets/cross-seed.age;
    owner = "rtorrent";
    group = "rtorrent";
  };

  systemd.services.cross-seed = {
    after = [ "rtorrent.service" ];
    requires = [ "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "rtorrent";
      Group = "rtorrent";
      EnvironmentFile = "${config.age.secrets.cross-seed.path}";
      WorkingDirectory = "/var/lib/cross-seed";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = "${pkgs.cross-seed}/bin/cross-seed daemon --torznab $trackers --exclude-older '720 days' --exclude-recent-search '90 days' --rss-cadence ${rss-cadence} --delay ${delay} --snatch-timeout ${snatch-timeout} --search-timeout ${search-timeout} --torrent-dir ${torrent-dir} --output-dir ${output-dir} --include-single-episodes --include-non-videos --action save --match-mode partial --verbose --fuzzy-size-threshold ${fuzzy-thr} --api-key $apikey";
      Restart = "always";
    };
  };
}
