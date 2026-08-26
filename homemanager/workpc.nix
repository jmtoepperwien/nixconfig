{
  config,
  pkgs,
  inputs,
  nixpkgs-unstable,
  ...
}:

let
  pkgs-unstable = import nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  home.username = "mtoepperwien";
  home.homeDirectory = "/home/mtoepperwien";
  home.stateVersion = "25.05";

  imports = [
    ./desktop.nix
    ./work.nix
  ];

  home.packages = [
    pkgs.btop-cuda
  ];

  # Prevent gpg from autostarting a local agent when the SSH-forwarded
  # gpg-agent socket momentarily looks unreachable, which would otherwise
  # delete and replace the forwarded socket with a local one.
  home.file.".gnupg/gpg.conf".text = ''
    no-autostart
  '';

  home.file.".config/sway/config" = {
    text = ''
      include workpc
      include common
      include nix-managed
    '';
  };

  programs.kitty.font.size = 12;
}
