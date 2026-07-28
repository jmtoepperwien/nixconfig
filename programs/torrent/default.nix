{ ... }:
{
  imports = [
    ./rtorrent.nix
    ./vpn-forwarding.nix
    ./flood.nix
    ./autobrr.nix
    ./cross-seed.nix
    ./autotorrent2.nix
  ];
}
