{ stdenv, lib, fetchzip, git, nodePackages, ... }:

let
  version = "1.27.1";
  src = fetchzip {
    url = "https://github.com/autobrr/autobrr/releases/download/v1.27.1/autobrr_1.27.1_linux_x86_64.tar.gz";
    hash = "sha256-Qh75rNXZNjNE1iYOEtvMiagQ1VT5PU9tlC/lsHm8OQg=";
    stripRoot = false;
  };
in stdenv.mkDerivation {
  name = "autobrr";
  version = version;
  src = src;
  unpackPhase = "";
  patchPhase = "";
  configurePhase = "";
  buildPhase = "";
  checkPhase = "";
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src/* $out/bin/
    runHook postInstall
  '';
}
