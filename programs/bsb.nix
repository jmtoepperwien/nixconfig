{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    qemu
    qemu_kvm
    gcc12
    gcc_multi
    binutils
    nasm
  ];
}
