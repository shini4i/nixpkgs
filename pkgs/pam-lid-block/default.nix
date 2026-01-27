{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  systemdLibs,
}:
/**
  * @name pkgs/pam-lid-block/default.nix
  * @description PAM helper utility to skip fingerprint authentication when laptop lid is closed.
  * Queries systemd-logind via D-Bus to check lid state. Returns 0 if lid is closed
  * (skip fingerprint), 1 if lid is open (proceed with fingerprint).
  */
stdenv.mkDerivation rec {
  pname = "pam-lid-block";
  version = "0-unstable-2026-01-27";

  src = fetchFromGitHub {
    owner = "shini4i";
    repo = "pam-lid-block";
    rev = "da5781c76d0c4ef9710a7314bdba6cecd67fc958";
    hash = "sha256-KcUylbE3TYOmSg4eXGr9kVNq2dVRGgdHT4dVh+CeBW0=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ systemdLibs ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    $CC -O2 -Wall -Wextra -fstack-protector-strong -fPIE \
        -DVERSION=\"${version}\" \
        $(pkg-config --cflags libsystemd) \
        -o check-lid src/check-lid.c \
        -pie $(pkg-config --libs libsystemd)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 check-lid $out/bin/check-lid

    runHook postInstall
  '';

  meta = with lib; {
    description = "PAM helper utility to skip fingerprint authentication when laptop lid is closed";
    longDescription = ''
      A PAM helper utility that queries systemd-logind via D-Bus to determine
      if the laptop lid is closed. When integrated with PAM configuration,
      it allows skipping fingerprint authentication in clamshell mode where
      the fingerprint scanner is physically inaccessible.

      Exit codes (PAM-compatible):
      - 0: Lid is CLOSED - skip fingerprint
      - 1: Lid is OPEN or error - proceed with fingerprint
    '';
    homepage = "https://github.com/shini4i/pam-lid-block";
    license = licenses.gpl3Only;
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "check-lid";
  };
}
