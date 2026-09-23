{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.flood
  ];

  systemd.services.flood = {
    enable = true;
    description = "Flood frontend for rtorrent";
    wants = [ "rtorrent.service" ];
    after = [ "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.flood}/bin/flood --rtsocket /run/rtorrent/rpc.sock --port 5678 --host 0.0.0.0 --baseuri /flood";
      Restart = "on-failure";
      Type = "simple";
      User = "rtorrent";
      Group = "rtorrent";
    };
  };

  services.rutorrent = {
    enable = false;
    group = "rtorrent";
    hostName = "0.0.0.0";
    nginx.enable = true;
  };

  networking.firewall.allowedTCPPorts = [
    5678
    5656
  ];
}
