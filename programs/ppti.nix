{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    qemu
    qemu_kvm
    gcc_multi
    libcxx
    binutils
    nasm
    bear
    cmake
    virt-manager
    virtiofsd
    gnome.gnome-boxes

  ];
}
