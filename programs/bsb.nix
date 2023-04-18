{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    qemu
    qemu_kvm
    gcc
    gcc_multi
    libcxx
    binutils
    nasm
  ];
}
