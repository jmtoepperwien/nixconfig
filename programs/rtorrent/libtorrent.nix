# Note: this is rakshasa's version of libtorrent, used mainly by rtorrent.
# *Do not* mistake it by libtorrent-rasterbar, used by Deluge, qbitttorent etc.
{ lib
, stdenv
, fetchFromGitHub
, autoconf-archive
, autoreconfHook
, cppunit
, libsigcxx
, openssl
, pkg-config
, zlib
}:

stdenv.mkDerivation rec {
  pname = "rakshasa-libtorrent";
  version = "0.13.8+date=2023-02-24";

  src = fetchFromGitHub {
    owner = "rakshasa";
    repo = "libtorrent";
    rev = "91f8cf4b0358d9b4480079ca7798fa7d9aec76b5";
    hash = "sha256-mEIrMwpWMCAA70Qb/UIOg8XTfg71R/2F4kb3QG38duU=";
  };

  nativeBuildInputs = [
    autoconf-archive
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    cppunit
    libsigcxx
    openssl
    zlib
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://github.com/rakshasa/libtorrent";
    description = "A BitTorrent library written in C++ for *nix, with focus on high performance and good code";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ ebzzry codyopel ];
    platforms = platforms.unix;
  };
}
