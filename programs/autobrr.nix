{ stdenv, lib, fetchzip, git, nodePackages, ... }:

let
  version = "1.29.0";
  src = fetchzip {
    url = "https://github.com/autobrr/autobrr/releases/download/v1.29.0/autobrr_1.29.0_linux_arm64.tar.gz";
    hash = "sha256-XeCnCH5ltjw/g3+Mrm8jlPC0PrI/uCFHbQ8jtSCvCiU=";
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
