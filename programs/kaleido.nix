{ lib
, stdenv
, fetchurl
, fetchzip
, fetchPypi
, python3Packages
}:

let 
  pname = "kaleido";
  version = "0.2.1";
  format = "wheel";
  wheelsrc = fetchurl {
    url = "https://github.com/plotly/Kaleido/releases/download/v0.2.1/kaleido-0.2.1-py2.py3-none-manylinux1_x86_64.whl";
    hash = "sha256-qiHPG/HHj4+lCp99ReEAPDh709b+CnZ8+780S5W9w6g=";
  };
in python3Packages.buildPythonPackage {
  inherit version pname format;
  #src = fetchPypi {
  #  inherit version pname format;
  #  sha256 = "sha256-RG5MOjKtkeSZdZ9qbVYNfLleEK6W31Rug0a1tm8hJaE=";
  #  python = "py3";
  #};
  src = wheelsrc;
  propagatedBuildInputs = [ python3Packages.setuptools ];
}

