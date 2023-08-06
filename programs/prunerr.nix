{ lib
, stdenv
, fetchurl
, fetchzip
, fetchPypi
, python3Packages
}:

let 
  pname = "prunerr";
  version = "1.1.13";
  format = "wheel";
  wheelsrc = fetchurl {
    url = "https://files.pythonhosted.org/packages/c9/8b/9e301c96f92ced4c43673ed060fc3f84475b3ed20788c6957587ae7d5641/prunerr-1.1.13-py3-none-any.whl";
    hash = "sha256-nsqksdIvEmyL93jeubMKQ6I6dtEPU9k7ORVhNDYq7Uc=";
  };
  arrapi = python3Packages.buildPythonPackage {
    pname = "arrapi";
    version = "1.4.2";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/a0/4d/f2efb1dab3a4703e99b14c858efe57746b941671b086bc74943b3656448c/arrapi-1.4.2-py3-none-any.whl";
      hash = "sha256-+8FyXwh/H1l3j/uPkHcIDwA1oQURJHoqFbKXU43ajWU=";
    };
    propagatedBuildInputs = [ python3Packages.requests ];
  };
  main-wrapper = python3Packages.buildPythonPackage {
    pname = "main-wrapper";
    version = "0.1.1";
    src = fetchPypi {
      pname = "main-wrapper";
      version = "0.1.1";
      sha256 = "sha256-c+m5MRuvLIClSmL89A37ipYCkK/kDaeScGatuX1TA0s=";
    };
    propagatedBuildInputs = [ python3Packages.setuptools python3Packages.setuptools-scm python3Packages.six ];
  };
  service-logging = python3Packages.buildPythonPackage {
    pname = "service-logging";
    version = "0.1.1";
    src = fetchPypi {
      pname = "service-logging";
      version = "0.1.1";
      sha256 = "sha256-YilxEUm2FIGI2U2VIYv4LfU1Q4IdTBbAED5pJhPOv0s=";
    };

    propagatedBuildInputs = [ python3Packages.setuptools python3Packages.setuptools-scm main-wrapper ];
  };
in python3Packages.buildPythonPackage {
  inherit version pname format;
  #src = fetchPypi {
  #  inherit version pname format;
  #  sha256 = "sha256-RG5MOjKtkeSZdZ9qbVYNfLleEK6W31Rug0a1tm8hJaE=";
  #  python = "py3";
  #};
  src = wheelsrc;
  propagatedBuildInputs = [ python3Packages.setuptools python3Packages.transmission-rpc python3Packages.argcomplete python3Packages.tenacity service-logging python3Packages.setuptools-scm python3Packages.pyyaml arrapi ];
}

