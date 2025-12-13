{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware/maltexps.nix
    ../graphical/greetd.nix
    ../graphical/environments-maltexps.nix
    ./desktop.nix
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    gutenprint
    gutenprintBin
  ];

  # fix suspend/wakeup
  systemd.sleep.extraConfig = "SuspendState=freeze";

  services.tlp.enable = true;

  hardware.cpu.intel.updateMicrocode = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vulkan-tools
      vulkan-headers
      vulkan-loader
    ];
  };

  nix.settings.max-jobs = 4;
  nix.settings.cores = 4;

  networking.hostName = "maltexps";

  system.stateVersion = "22.11";
}
