{ lib
, stdenv
, fetchurl
, fetchFromGitHub
, autoreconfHook
, autoconf-archive
, cppunit
, curl
, libsigcxx
, libtool
, libtorrent-rasterbar
, ncurses
, openssl
, pkg-config
, xmlrpc_c
, zlib
}:

stdenv.mkDerivation rec {
  pname = "rakshasa-rtorrent";
  version = "0.9.8+date=2023-07-17";

  src = fetchFromGitHub {
    owner = "rakshasa";
    repo = "rtorrent";
    rev = "1da0e3476dcabbf74b2e836d6b4c37b4d96bde09";
    hash = "sha256-HTwAs8dfZVXfLRNiT6QpjKGnuahHfoMfYWqdKkedUL0=";
  };

  passthru = {
    inherit libtorrent-rasterbar;
  };

  nativeBuildInputs = [
    autoconf-archive
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    cppunit
    curl
    libsigcxx
    libtool
    libtorrent-rasterbar
    ncurses
    openssl
    xmlrpc_c
    zlib
  ];

  configureFlags = [
    "--with-xmlrpc-c"
    "--with-posix-fallocate"
  ];

  enableParallelBuilding = true;

  postInstall = ''
    mkdir -p $out/share/man/man1 $out/share/doc/rtorrent
    mv doc/old/rtorrent.1 $out/share/man/man1/rtorrent.1
    mv doc/rtorrent.rc $out/share/doc/rtorrent/rtorrent.rc
  '';

  meta = with lib; {
    homepage = "https://rakshasa.github.io/rtorrent/";
    description = "An ncurses client for libtorrent, ideal for use with screen, tmux, or dtach";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ ebzzry codyopel ];
    platforms = platforms.unix;
    mainProgram = "rtorrent";
  };
}
