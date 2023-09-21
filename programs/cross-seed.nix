{ lib
, stdenv
, fetchzip
, buildNpmPackage
, python3
}:

let 
  version = "v5.4.5";
  src = fetchzip {
    url = "https://github.com/cross-seed/cross-seed/archive/refs/tags/${version}.tar.gz";
    hash = "sha256-V2citKz4rqkSXVqsKZj6vB2XVh9uim67J/MXe+z2GBg=";
  };
in buildNpmPackage {
  pname = "cross-seed";
  inherit version;
  inherit src;
  npmDepsHash = "sha256-C2j4Fq2+Ob1ra3Z7IQb/ZYGp3uz0PAQBCRM7WRHTEUs=";

  buildInputs = [ python3 ];
  nativeBuildInputs = [ python3 ];
}

