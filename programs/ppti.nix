{
  config,
  lib,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    gcc_multi
    libcxx
    binutils
    nasm
    bear
    cmake
    gnome-boxes

  ];
}
