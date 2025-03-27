{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  autoreconfHook,
  autoconf-archive,
  cppunit,
  curl,
  libsigcxx,
  libtool,
  libtorrent,
  ncurses,
  openssl,
  pkg-config,
  xmlrpc_c,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "rakshasa-rtorrent";
  version = "0.9.8+date=2023-03-16";

  src = fetchFromGitHub {
    owner = "rakshasa";
    repo = "rtorrent";
    rev = "1da0e3476dcabbf74b2e836d6b4c37b4d96bde09";
    hash = "sha256-mEIrMwpWMCAA70Qb/UIOg8XTfg71R/2F4kb3QG38duU=";
  };

  passthru = {
    inherit libtorrent;
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
    libtorrent
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
  '';

  meta = with lib; {
    homepage = "https://rakshasa.github.io/rtorrent/";
    description = "An ncurses client for libtorrent, ideal for use with screen, tmux, or dtach";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      ebzzry
      codyopel
    ];
    platforms = platforms.unix;
    mainProgram = "rtorrent";
  };
}
