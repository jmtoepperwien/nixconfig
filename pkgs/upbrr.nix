{
  lib,
  stdenv,
  buildGoModule,
  stdenvNoCC,
  nix-update-script,
  nodejs,
  pnpm_11,
  fetchPnpmDeps,
  pnpmConfigHook,
  typescript,
  version,
  src,
  src-web,
}:

let
  pname = "upbrr";

  upbrr-web = stdenvNoCC.mkDerivation {
    pname = "${pname}-web";
    inherit version;

    src = src-web;

    nativeBuildInputs = [
      nodejs
      pnpmConfigHook
      pnpm_11
      typescript
    ];

    pnpmDeps = fetchPnpmDeps {
      inherit (upbrr-web)
        pname
        version
        src
        ;
      pnpm = pnpm_11;
      fetcherVersion = 4;
      hash = "sha256-eMpoFe+TfD1MVQM4JrXrfgc4MNjkeDT3GAVXJ8sbp/A=";
    };

    postBuild = ''
      pnpm run build:bundle
    '';

    installPhase = ''
      cp -r dist $out
    '';
  };
in
buildGoModule (finalAttrs: {
  inherit
    pname
    version
    src
    ;

  vendorHash = "sha256-fbqCCmSPfjtwyUituQ/wXvsm6Xs6QyJjvKOlpuPkr3w=";

  preBuild = ''
    cp -r ${finalAttrs.passthru.upbrr-web} internal/webserver/assets/
  '';

  ldflags = [
    "-X main.version=${finalAttrs.version}"
    "-X main.commit=v${finalAttrs.version}"
  ];

  doCheck = false;

  passthru = {
    inherit upbrr-web;
    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "upbrr-web"
      ];
    };
  };

  meta = {
    description = "Guided upload preparation app for private-tracker workflows";
    license = lib.licenses.gpl2Plus;
    homepage = "https://upbrr.com/";
    mainProgram = "upbrr";
    platforms = with lib.platforms; linux ++ darwin;
  };
})
