{ pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];
  environment.systemPackages = [ pkgs.neovim ];
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../authorized_keys
  ];
}
