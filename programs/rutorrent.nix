{ stdenv, lib, fetchFromGitHub, ... }:

let
  version = "4.1.1";
  src = fetchFromGitHub {
    owner = "Novik";
    repo = "ruTorrent";
    rev = "v4.1.1";
    sha256 = "sha256-g2vmTueLOH82VBysXzwxwhxspP93XCZs1CocEZ6QSO0=";
  };
in stdenv.mkDerivation {
  name = "ruTorrent";
  src = src;
  installPhase = ''
    runHook preInstall
    mkdir $out
    cp -r ./* $out
    runHook postInstall
  '';
}
