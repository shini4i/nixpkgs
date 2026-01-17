{
  lib,
  stdenv,
  fetchFromGitHub,
}:
/**
  * @name pkgs/gnome-shell-extension-apple-studio-display/default.nix
  * @description GNOME Shell extension for Apple Studio Display brightness control.
  * Provides a Quick Settings panel integration for controlling brightness of
  * Apple Studio Display monitors. Requires the asd-brightness-daemon D-Bus
  * service to be running for actual hardware communication.
  */
stdenv.mkDerivation rec {
  pname = "gnome-shell-extension-apple-studio-display";
  version = "0.1.0-unstable-2026-01-18";

  src = fetchFromGitHub {
    owner = "shini4i";
    repo = "gnome-shell-extension-apple-studio-display";
    rev = "599d8c56039e2d1663a5d244ce5b76a2352d13d8";
    hash = "sha256-NWQr+YCQOfzgbJmQKGSp2HdkRsd6P0G898RTJ5YHZNk=";
  };

  uuid = "asd-brightness@shini4i.github.io";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Install extension files
    extensionDir="$out/share/gnome-shell/extensions/${uuid}"
    mkdir -p "$extensionDir"

    cp -r \
      extension/extension.js \
      extension/metadata.json \
      extension/stylesheet.css \
      extension/lib \
      extension/ui \
      extension/icons \
      "$extensionDir/"

    runHook postInstall
  '';

  passthru.extensionUuid = uuid;

  meta = with lib; {
    description = "Control Apple Studio Display brightness from GNOME Quick Settings";
    longDescription = ''
      A GNOME Shell extension that integrates Apple Studio Display brightness
      controls into the Quick Settings panel. Provides per-display brightness
      sliders with automatic detection of connected displays.

      Features:
      - Individual brightness sliders for each connected display
      - Hot-plug support via udev events
      - GNOME 47+ compatibility

      Requires the asd-brightness-daemon package for D-Bus communication with
      the display hardware.
    '';
    homepage = "https://github.com/shini4i/gnome-shell-extension-apple-studio-display";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
