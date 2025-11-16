{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware/worknotebook.nix
    ./hardware/worknotebook_disko.nix
    ../graphical/greetd.nix
    ./desktop.nix
  ];
  environment.systemPackages = with pkgs; [
    clinfo
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # gpu
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  # vulkan
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-tools
    vulkan-headers
    vulkan-loader
  ];

  nix.settings.max-jobs = 10;
  nix.settings.cores = 10;

  networking.hostName = "jmtoepperwiennotebook";
  system.stateVersion = "25.05"; # Did you read the comment?
}
