{
  lib,
  stdenv,
  fetchFromGitHub,
  glib,
}:
/**
* @name pkgs/gnome-shell-extension-elgato-lights/default.nix
* @description GNOME Shell extension for controlling Elgato Key Lights from the
* Quick Settings panel. Provides brightness, temperature, and on/off controls
* with automatic mDNS discovery of lights on the network.
*/
stdenv.mkDerivation rec {
  pname = "gnome-shell-extension-elgato-lights";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "shini4i";
    repo = "gnome-shell-extension-elgato-lights";
    rev = "v0.1.2";
    sha256 = "sha256-m+/hca9J9zi5YfSLDGejJGiE95VGvFNHnUoiKd2YhNA=";
  };

  nativeBuildInputs = [glib];

  uuid = "elgato-lights@shini4i.github.io";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Install extension files
    extensionDir="$out/share/gnome-shell/extensions/${uuid}"
    mkdir -p "$extensionDir"

    cp -r \
      extension.js \
      elgatoApi.js \
      discovery.js \
      metadata.json \
      stylesheet.css \
      lib \
      icons \
      "$extensionDir/"

    # Install schemas in extension directory (where GNOME Shell looks for them)
    mkdir -p "$extensionDir/schemas"
    cp schemas/*.gschema.xml "$extensionDir/schemas/"
    glib-compile-schemas "$extensionDir/schemas"

    runHook postInstall
  '';

  passthru.extensionUuid = uuid;

  meta = with lib; {
    description = "Control Elgato Key Lights from GNOME Quick Settings";
    homepage = "https://github.com/shini4i/gnome-shell-extension-elgato-lights";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
