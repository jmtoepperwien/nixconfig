{
  config,
  lib,
  pkgs,
  ...
}:

{
  #nixpkgs.overlays = [ (final: prev: {
  #  irssi =  prev.irssi.overrideAttrs ( oldAttrs: rec {
  #    buildInputs = with pkgs; [
  #      glib
  #      libgcrypt
  #      libintl
  #      libotr
  #      ncurses
  #      openssl
  #      (perl.withPackages ( ps: with ps; [ libwwwperl ] ))
  #    ];
  #    } );
  #})];
  systemd.services."weechat" = {
    enable = false;
    description = "weechat irc client inside tmux";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "forking";
      User = "pi4";
      TimeoutSec = "5";
      Environment = "WIDTH=80 HEIGHT=24";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.tmux}/bin/tmux -L weechat new -d -s weechat ${pkgs.weechat}/bin/weechat'";
      ExecStop = "${pkgs.tmux}/bin/tmux -L weechat kill-session -t weechat";
    };
  };
}
