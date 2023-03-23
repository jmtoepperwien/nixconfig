{ config, pkgs, lib, modulesPath, inputs, ... }:

{
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = lib.mkForce false;
    settings.KbdInteractiveAuthentication = lib.mkForce false;
    settings.PermitRootLogin = lib.mkForce "no"; # nixos-generators will try to put this to true for first install
    extraConfig = ''
      UsePam no
    '';
  };
}
