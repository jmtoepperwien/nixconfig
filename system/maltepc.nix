{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    ./hardware/maltepc.nix
    ../graphical/greetd.nix
    ./desktop.nix
  ];
  environment.systemPackages = with pkgs; [
    virt-manager
    virtiofsd
    gnome-boxes
    clinfo
  ];

  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # gpu
  hardware.graphics.enable = true;
  # vulkan
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-tools
    vulkan-headers
    vulkan-loader
    rocmPackages.clr.icd
    amdvlk
  ];

  # virtualisation
  virtualisation.virtualbox.host.enable = false;
  users.extraGroups.vboxusers.members = [ "user-with-access-to-virtualbox" ];
  virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [(pkgs.OVMF.override {
          secureBoot = true;
          tpmSupport = true;
        }).fd];
      };
    };
  };
  programs.virt-manager.enable = true;

  nix.settings.max-jobs = 6;
  nix.settings.cores = 6;

  networking.hostName = "maltepc";

  system.stateVersion = "22.11"; # Did you read the comment?
}
