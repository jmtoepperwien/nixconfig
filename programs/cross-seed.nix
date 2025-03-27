{
  lib,
  stdenv,
  fetchzip,
  buildNpmPackage,
  python3,
}:

let
  version = "v5.9.2";
  src = fetchzip {
    url = "https://github.com/cross-seed/cross-seed/archive/refs/tags/${version}.tar.gz";
    hash = "sha256-E0AlsFV9RP01YVwjw6ZQ8Lf1IVyuudxrb5oJ61EfIyo=";
  };
in
buildNpmPackage {
  pname = "cross-seed";
  inherit version;
  inherit src;
  npmDepsHash = "sha256-hZKLv+bzRFiMjNemydCUC1d7xul7Mm+vOPtCUD7p9XQ=";

  buildInputs = [ python3 ];
  nativeBuildInputs = [ python3 ];
}
