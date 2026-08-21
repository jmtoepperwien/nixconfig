{
  lib,
  stdenv,
  buildGoModule,
  src,
  bootstrapMain,
}:

buildGoModule {
  pname = "upbrr-bootstrap-auth";
  version = "0.3.1";

  inherit src;

  vendorHash = "sha256-fbqCCmSPfjtwyUituQ/wXvsm6Xs6QyJjvKOlpuPkr3w=";

  # Inject our bootstrap main.go into the upbrr source so it can use the
  # internal/authmaterial package (Go's internal-package rule requires this).
  prePatch = ''
    mkdir -p cmd/upbrr-bootstrap-auth
    cp ${bootstrapMain} cmd/upbrr-bootstrap-auth/main.go
  '';

  subPackages = [ "cmd/upbrr-bootstrap-auth" ];

  ldflags = [ "-X main.version=0.3.1" ];

  doCheck = false;

  meta = {
    description = "Bootstrap helper for upbrr's web-auth.json (Argon2id + seed)";
    license = lib.licenses.gpl2Plus;
    homepage = "https://upbrr.com/";
    mainProgram = "upbrr-bootstrap-auth";
    platforms = with lib.platforms; linux ++ darwin;
  };
}
