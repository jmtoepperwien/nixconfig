{
  stdenv,
  lib,
  fetchzip,
  git,
  nodePackages,
  ...
}:

let
  version = "1.60.0";
  src = fetchzip {
    url = "https://github.com/autobrr/autobrr/releases/download/v${version}/autobrr_${version}_linux_x86_64.tar.gz";
    hash = "sha256-T3G471y5nn4xyZpgd6tTXzgmELaFFRE4rkJDbzigJfk=";
    stripRoot = false;
  };
in
stdenv.mkDerivation {
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
