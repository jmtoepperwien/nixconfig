{ config, pkgs, lib, modulesPath, inputs, ... }:

{
  services.openssh = {
    enable = true;
    settings.passwordAuthentication = false;
    settings.kbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };
}
