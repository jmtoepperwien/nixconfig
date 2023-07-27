{ stdenv, lib, fetchzip, git, nodePackages, ... }:

let
  version = "1.27.1";
  src = fetchzip {
    url = "https://github.com/autobrr/autobrr/releases/download/v1.27.1/autobrr_1.27.1_linux_arm64.tar.gz";
    hash = "sha256-M5MIw7hyKhd9EALqmAXAtGmPC2flv1ULAejCg/O61uE=";
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
