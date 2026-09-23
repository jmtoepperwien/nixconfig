{ config, pkgs, ... }:
let
  rss-cadence = "30min";
  delay = "60";
  snatch-timeout = "5min";
  search-timeout = "5min";
  torrent-dir = "/var/lib/rtorrent/session";
  # Must share a mountpoint/device with rtorrent's actual downloaded data
  # (zstorage) for hardlink injection to succeed - /var/lib is on zroot.
  link-dir = "${config.server.media_folder}/downloads/torrent/cross-seed-links";
  fuzzy-thr = "0.1";
  # nodejs 24 (nixpkgs default) hits an upstream flaky-crash bug in native
  # addon cleanup hooks (nodejs/node#63923), which better-sqlite3 trips
  # during statement/database teardown ("Assertion failed: (env) !=
  # nullptr" in RemoveEnvironmentCleanupHook). Pin to nodejs_22 (LTS) to
  # avoid the crash loop.
  cross-seedPackage = pkgs.cross-seed.override {
    buildNpmPackage = pkgs.buildNpmPackage.override { nodejs = pkgs.nodejs_22; };
  };
in
{
  environment.systemPackages = [
    cross-seedPackage
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/cross-seed 0755 rtorrent rtorrent"
    "d ${link-dir} 0775 rtorrent rtorrent"
  ];

  age.secrets.cross-seed = {
    file = ../../secrets/cross-seed.age;
    owner = "rtorrent";
    group = "rtorrent";
  };

  systemd.services.cross-seed = {
    after = [
      "rtorrent.service"
      "rtorrent-rpc-http.service"
    ];
    wants = [
      "rtorrent.service"
      "rtorrent-rpc-http.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "rtorrent";
      Group = "rtorrent";
      EnvironmentFile = "${config.age.secrets.cross-seed.path}";
      WorkingDirectory = "/var/lib/cross-seed";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = "${cross-seedPackage}/bin/cross-seed daemon --torznab $trackers --exclude-older '720 days' --exclude-recent-search '90 days' --rss-cadence ${rss-cadence} --delay ${delay} --snatch-timeout ${snatch-timeout} --search-timeout ${search-timeout} --torrent-dir ${torrent-dir} --torrent-clients rtorrent:http://127.0.0.1:8001/RPC2 --link-dirs ${link-dir} --link-type hardlink --include-single-episodes --include-non-videos --action inject --match-mode partial --verbose --fuzzy-size-threshold ${fuzzy-thr} --api-key $apikey";
      Restart = "always";
    };
  };
}
