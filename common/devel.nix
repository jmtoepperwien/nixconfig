{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # man pages for linux api not there by default
    man-pages
    man-pages-posix
    gnumake
    cmake
    git
    gnused
    xz
    zip
    gnutar
    llvmPackages.libunwind
    llvmPackages.libcxxStdenv
    llvmPackages.libcxxClang
    libcxx
    gcc
    lua
    lua51Packages.lua
    luajit
  ];
  documentation.dev.enable = true;
}
