{ pkgs, inputs, ... }:
{
  services.music-assistant = {
    enable = true;
    # 2.8.7 (stable pin) predates the fix for Spotify's refresh-token
    # rotation (KeyError: 'refresh_token'); pull a newer build from unstable.
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.music-assistant;
    providers = [
      "spotify" # Spotify music source/library browsing (shares deps with spotify_connect)
      "spotify_connect" # Spotify Connect target, phone/desktop casts to it
      "musiccast" # native Yamaha MusicCast player support
      "squeezelite" # slimproto server for moOde/LibreELEC Squeezelite renderers
      "snapcast" # built-in snapserver, for any snapclient-based receivers
      "dlna" # generic UPnP/DLNA renderer support
      "airplay" # for synced groups with AirPlay-capable devices (e.g. Yamaha MusicCast AVRs)
      "sendspin" # airplay provider hard-imports aiosendspin for its bridge feature
      "chromecast" # cast to existing Chromecast/Google Cast hardware
    ];
  };

  # spotify_connect on this MA release shells out to go-librespot, which
  # nixpkgs' music-assistant module doesn't yet add to PATH.
  systemd.services.music-assistant.path = [
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.go-librespot
  ];

  # spotify_connect (and player discovery in general) use randomized ports
  # with no way to pin them; Music Assistant's own docs say running it behind
  # a restrictive firewall isn't supported. Trust the home LAN subnet outright
  # instead of chasing ports. Scoped to this subnet only, WAN/tunnel
  # interfaces are untouched. Adjust the CIDR if your LAN isn't 192.168.1.0/24.
  networking.firewall.extraInputRules = ''
    ip saddr 192.168.1.0/24 accept
  '';
}
