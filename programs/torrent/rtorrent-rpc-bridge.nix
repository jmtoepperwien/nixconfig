{ pkgs, ... }:
{
  # HTTP-to-SCGI bridge for rtorrent's RPC, reachable from inside the vpn
  # netns. cross-seed's rtorrent client only speaks XML-RPC over HTTP(S)
  # (via the 'xmlrpc' npm client), it cannot talk to rtorrent's SCGI unix
  # socket directly, so it needs the same translation nginx already does
  # on the host network at /RPC2 - but that nginx instance lives outside
  # the vpn netns and isn't reachable from it. This runs a second, minimal
  # nginx just for that bridge, inside the same netns as rtorrent and
  # cross-seed, on loopback only.
  systemd.services.rtorrent-rpc-http = {
    description = "HTTP-to-SCGI bridge for rtorrent RPC (vpn netns)";
    bindsTo = [ "netns-vpn.service" "rtorrent.service" ];
    after = [ "netns-vpn.service" "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/vpn";
      User = "rtorrent";
      Group = "media";
      RuntimeDirectory = "rtorrent-rpc-http";
      ExecStart =
        let
          conf = pkgs.writeText "rtorrent-rpc-http.conf" ''
            daemon off;
            pid /run/rtorrent-rpc-http/nginx.pid;
            error_log /dev/stderr;
            events {}
            http {
              client_body_temp_path /run/rtorrent-rpc-http/client_body;
              proxy_temp_path /run/rtorrent-rpc-http/proxy;
              server {
                listen 127.0.0.1:8001;
                location /RPC2 {
                  include ${pkgs.nginx}/conf/scgi_params;
                  scgi_pass unix:/run/rtorrent/rpc.sock;
                }
              }
            }
          '';
        in
        "${pkgs.nginx}/bin/nginx -c ${conf}";
      Restart = "always";
    };
  };
}
