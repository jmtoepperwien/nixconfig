{ lib, pkgs, ... }:
let
  version = "2.10.5";

  # nixpkgs' default patchelf (0.15.2) clobbers ELF sections when rewriting
  # the interpreter/rpath, which corrupts the offset that .NET's single-file
  # bundle host uses to locate its appended payload ("Arithmetic overflow
  # while reading bundle" at runtime). patchelf >= 0.19.0 added
  # --no-clobber-old-sections specifically to patch in place instead.
  patchelf_0_19 = pkgs.patchelf.overrideAttrs (_old: {
    version = "0.19.0";
    src = pkgs.fetchurl {
      url = "https://github.com/NixOS/patchelf/releases/download/0.19.0/patchelf-0.19.0.tar.gz";
      hash = "sha256-R4LljX3V3q4/jSFfhvlP2g49BytYP1rUQ4RvM4H7Ryo=";
    };
  });

  # --no-clobber-old-sections can only reuse the byte space the original
  # rpath/dynstr entries already occupied, so a long colon-joined
  # makeLibraryPath string gets silently truncated. Merge the needed libs
  # into one directory instead, keeping the rpath a single short path.
  runtimeLibs = pkgs.buildEnv {
    name = "cleanuparr-runtime-libs";
    paths = map lib.getLib [
      pkgs.stdenv.cc.cc
      pkgs.openssl
    ];
    pathsToLink = [ "/lib" ];
    ignoreCollisions = true;
  };

  cleanuparrPackage = pkgs.stdenv.mkDerivation {
    pname = "cleanuparr";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/Cleanuparr/Cleanuparr/releases/download/v${version}/Cleanuparr-${version}-linux-amd64.zip";
      hash = "sha256-Xnmmq5K+2rV2iDz9PuutelmuR2oR4H1cO4l5Va/zqso=";
    };

    nativeBuildInputs = [
      pkgs.unzip
      patchelf_0_19
    ];

    dontConfigure = true;
    dontBuild = true;
    # The release binary is a self-contained single-file .NET bundle: the
    # managed payload is appended after the recognized ELF sections. Nix's
    # default fixup-phase `strip` doesn't know about that trailing data and
    # truncates the file down to just the native host stub, destroying it.
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/cleanuparr
      cp -r . $out/lib/cleanuparr/
      chmod +x $out/lib/cleanuparr/Cleanuparr

      patchelf --no-clobber-old-sections \
        --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
        --set-rpath "${runtimeLibs}/lib" \
        $out/lib/cleanuparr/Cleanuparr

      runHook postInstall
    '';

    meta = {
      description = "Automated download cleanup for the Servarr ecosystem";
      homepage = "https://github.com/Cleanuparr/Cleanuparr";
      license = lib.licenses.gpl3Only;
      platforms = [ "x86_64-linux" ];
      mainProgram = "Cleanuparr";
    };
  };
in
{
  users.groups."cleanuparr" = { };
  users.users."cleanuparr" = {
    isSystemUser = true;
    group = "cleanuparr";
    extraGroups = [ "media" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/cleanuparr 0750 cleanuparr cleanuparr"
  ];

  systemd.services.cleanuparr = {
    description = "Cleanuparr";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    environment = {
      PORT = "11011";
      BASE_PATH = "/cleanuparr";
      CLEANUPARR_CONFIG_PATH = "/var/lib/cleanuparr";
      DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1";
    };
    serviceConfig = {
      User = "cleanuparr";
      Group = "media";
      UMask = "0002";
      WorkingDirectory = "${cleanuparrPackage}/lib/cleanuparr";
      ExecStart = "${cleanuparrPackage}/lib/cleanuparr/Cleanuparr";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
