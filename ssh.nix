{ config, pkgs, lib, modulesPath, inputs, ... }:

{
  services.openssh = {
    enable = true;
    settings.passwordAuthentication = false;
    settings.kbdInteractiveAuthentication = false;
    settings.PermitRootLogin = lib.mkDefault "no"; # nixos-generators will put this to true for first install
  };
}
