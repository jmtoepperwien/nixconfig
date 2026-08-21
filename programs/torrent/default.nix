{ ... }:
{
  imports = [
    ./rtorrent.nix
    ./vpn-forwarding.nix
    ./flood.nix
    ./autobrr.nix
    ./rtorrent-rpc-bridge.nix
    ./upbrr.nix
    ./cross-seed.nix
  ];
}
