{ stdenv, lib, fetchFromGitHub, ... }:

let
  version = "20220126";
  src = fetchFromGitHub {
    owner = "shuber2";
    repo = "mutt-gruvbox";
    rev = "91853cfee609ecad5d2cb7dce821a7dfe6d780ef";
    sha256 = "sha256-TFxVG2kp5IDmkhYuzhprEz2IE28AEMAi/rUHILa7OPU=";
  };
in stdenv.mkDerivation {
  installPhase = ''
    runHook preInstall
    mkdir $out
    cp -r ./* $out
    runHook postInstall
  '';
  name = "mutt-gruvbox-theme";
  src = src;
}
