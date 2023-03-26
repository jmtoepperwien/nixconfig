{ config, pkgs, lib, modulesPath, inputs, ... }:

{
  programs.ssh.package = pkgs.openssh_hpn;
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings.PasswordAuthentication = lib.mkForce false;
    settings.KbdInteractiveAuthentication = lib.mkForce false;
    settings.PermitRootLogin = lib.mkForce "no"; # nixos-generators will try to put this to true for first install
  };
}
