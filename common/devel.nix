{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.gnumake
    pkgs.cmake
    pkgs.git
    pkgs.gnused
    pkgs.xz
    pkgs.zip
    pkgs.gnutar
    pkgs.llvmPackages.libunwind
    pkgs.llvmPackages.libcxxStdenv
    pkgs.llvmPackages.libcxxClang
    pkgs.libcxx
    pkgs.gcc
    pkgs.lua
    pkgs.lua51Packages.lua
    pkgs.luajit
  ];
}
