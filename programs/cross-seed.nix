{ lib
, stdenv
, fetchzip
, buildNpmPackage
, python3
}:

let 
  version = "v5.4.0";
  src = fetchzip {
    url = "https://github.com/cross-seed/cross-seed/archive/refs/tags/${version}.tar.gz";
    hash = "sha256-25OnqfhsplnJBZObwPd26kjRMx9MBBm1y15+Dl65P74=";
  };
in buildNpmPackage {
  pname = "cross-seed";
  inherit version;
  inherit src;
  npmDepsHash = "sha256-TexcJ7rYUe0UxE1XlLQ1z59NjcW5a2rnxsKegecRhHI=";

  buildInputs = [ python3 ];
  nativeBuildInputs = [ python3 ];
}

