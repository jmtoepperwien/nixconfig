{ pkgs, ... }:
let
  # cross-seed's rtorrent client injects torrents stopped, hash-checks them,
  # then resumes them itself once the check passes - but that resume relies
  # on an in-process async loop that can die (service restart, or the known
  # upstream rtorrent quirk where a resumed torrent silently flips back to
  # paused; see cross-seed/cross-seed#261, #430). This periodically re-syncs
  # any complete-but-paused cross-seed torrent back to active.
  script = pkgs.writers.writePython3 "cross-seed-resume-watchdog" { } ''
    import xmlrpc.client

    TAG = "cross-seed"
    proxy = xmlrpc.client.ServerProxy("http://127.0.0.1:8001/RPC2")

    rows = proxy.d.multicall2(
        "",
        "main",
        "d.hash=",
        "d.name=",
        "d.complete=",
        "d.is_active=",
        "d.left_bytes=",
        "d.custom1=",
    )

    for hash_, name, complete, is_active, left_bytes, custom1 in rows:
        if TAG not in custom1.split(","):
            continue
        # Resume any inactive cross-seed torrent. This catches both:
        #   - complete torrents that flipped back to paused (cross-seed
        #     injects stopped, then re-resumes via in-process loop that
        #     can die or get reverted by an rtorrent client quirk; see
        #     cross-seed/cross-seed#261, #430)
        #   - partially downloaded torrents that were resumed by
        #     cross-seed's own loop, then stopped again
        # If a torrent has been deliberately paused long-term, the next
        # timer cycle will resume it again - we accept that trade-off
        # per the design decision.
        if not is_active:
            print(
                f"Resuming inactive cross-seed torrent: {name} [{hash_}] "
                f"(complete={complete}, left_bytes={left_bytes})"
            )
            proxy.d.resume(hash_)
  '';
in
{
  systemd.services.cross-seed-resume-watchdog = {
    description = "Resume cross-seed torrents stuck paused after injection";
    after = [ "rtorrent-rpc-http.service" ];
    requires = [ "rtorrent-rpc-http.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "rtorrent";
      Group = "rtorrent";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = "${script}";
    };
  };

  systemd.timers.cross-seed-resume-watchdog = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
    };
  };
}
