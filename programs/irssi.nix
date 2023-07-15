{ config, lib, pkgs, ... }:

{
  nixpkgs.overlays = [ (final: prev: {
    irssi =  prev.irssi.overrideAttrs ( oldAttrs: rec {
      buildInputs = with pkgs; [
        glib
        libgcrypt
        libintl
        libotr
        ncurses
        openssl
        (perl.withPackages ( ps: with ps; [ libwwwperl ] ))
      ];
      } );
  })];
  systemd.services."irssi" = {
    enable = true;
    description = "irssi irc client inside tmux";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "forking";
      User = "pi4";
      TimeoutSec = "5";
      Environment = "WIDTH=80 HEIGHT=24";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.tmux}/bin/tmux -L %p -2 new-session -A -d -x $WIDTH -y $HEIGHT -s irssi ${pkgs.irssi}/bin/irssi'";
      ExecStop = ''
        ${pkgs.tmux}/bin/tmux -L %p send-keys -t irssi:0 C-u
        ${pkgs.tmux}/bin/tmux -L %p send-keys -t irssi:0 \quit\" Enter"
        ${pkgs.bash}/bin/bash -c '${pkgs.toybox}/bin/timeout 3 ${pkgs.toybox}/bin/tail --pid=$(${pkgs.toybox}/bin/cat %t/irssi.pid || ${pkgs.toybox}/bin/echo 0) -f /dev/null'
        -${pkgs.tmux}/bin/tmux -L %p kill-session -t irssi
      '';
    };
  };
}
