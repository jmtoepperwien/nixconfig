{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    haskell-language-server
    ghc
    ghcid
    cabal
  ];
}
