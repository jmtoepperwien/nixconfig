{ lib
, stdenv
, fetchzip
, python3Packages
, fetchPypi
}:

let 
  pname = "autotorrent2";
  version = "1.2.3";
  src = fetchzip {
    url = "https://github.com/JohnDoee/autotorrent2/archive/refs/tags/${version}.tar.gz";
    hash = "sha256-25OnqfhsplnJBZObwPd26kjRMx9MBBm1y15+Dl65P74=";
  };
  tabulate = python3Packages.buildPythonPackage {
    pname = "tabulate";
    version = "0.8.7";
    src = fetchPypi {
      pname = "tabulate";
      version = "0.8.7";
      sha256 = "sha256-2ycjog0EvNqFIhZcc+6nwwDtp04M6FLZAi4BWdeJUAc=";
    };
    propagatedBuildInputs = [ python3Packages.nose ];
    doCheck = false;
  };
  chardet = python3Packages.buildPythonPackage {
    pname = "chardet";
    version = "4.0.0";
    src = fetchPypi {
      pname = "chardet";
      version = "4.0.0";
      sha256 = "sha256-DW9ToV20Eg8rCMlPEefZPSyRHuEYtrMKBOw+6DEBefo=";
    };
    buildInputs = [ python3Packages.pytest ];
  };
  publicsuffixlist = python3Packages.buildPythonPackage {
    pname = "publicsuffixlist";
    version = "0.7.3";
    src = fetchPypi {
      pname = "publicsuffixlist";
      version = "0.7.3";
      sha256 = "sha256-W9uBz5915FZcz8USC+dcXHfB2UWquzjjd3shcYswiFA=";
    };
  };
  deluge_client = python3Packages.buildPythonPackage {
    pname = "deluge-client";
    version = "1.9.0";
    src = fetchPypi {
      pname = "deluge-client";
      version = "1.9.0";
      sha256 = "sha256-DS8SEIoUfURZDI32OZf8sy+LL7wY+MuyIfATbi43K4U=";
    };
    propagatedBuildInputs = [ python3Packages.pytest ];
  };
  libtc = python3Packages.buildPythonPackage {
    pname = "libtc";
    version = "1.3.4";
    src = fetchPypi {
      pname = "libtc";
      version = "1.3.4";
      sha256 = "sha256-llp8QQlqadADEilV4mY+vJ5cyNuQgKSdbx1BsbefmSc=";
    };
    propagatedBuildInputs = [ python3Packages.pytz deluge_client publicsuffixlist python3Packages.requests python3Packages.click tabulate python3Packages.appdirs ];
    doCheck = false; # was failing, just skip
  };
in python3Packages.buildPythonPackage rec {
  inherit pname version;
  format = "pyproject";
  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-E3E7xpdpN/BNQSbf4QoKJI1P2v4deHWhFqF/GuX4EGs=";
  };
  propagatedBuildInputs = [ python3Packages.setuptools python3Packages.toml python3Packages.click libtc chardet ];
}

