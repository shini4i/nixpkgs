# openfortivpn-gui - GTK4/libadwaita GUI client for Fortinet SSL VPN
# Wraps openfortivpn CLI tool with a modern desktop interface
#
# This package includes:
# - openfortivpn-gui: The main GTK4/libadwaita GUI application
# - openfortivpn-gui-helper: Privileged helper daemon for password-less VPN operations
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchurl,
  pkg-config,
  wrapGAppsHook4,
  gobject-introspection,
  gtk4,
  libadwaita,
  glib,
  libsecret,
  openfortivpn,
  librsvg,
}:

buildGoModule rec {
  pname = "openfortivpn-gui";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "shini4i";
    repo = "openfortivpn-gui";
    rev = "v0.2.0";
    hash = "sha256-6qphTtLPg85LYjOzlmuKcifNglxh4brYbbfcdytkSIk=";
  };

  vendorHash = "sha256-REBq9xL2ybU+cGAvTTkyFiv29y9T56f/i+YN7eDTTMk=";

  # Fortinet VPN icon from official Fortinet icon library.
  # Note: External URL may change; hash ensures integrity and reproducibility.
  icon = fetchurl {
    url = "https://icons.fortinet.com/icons/New%20-%20Updated%20icons%20for%202024/April%202k24/VPN.svg";
    hash = "sha256-WI8LseHqjLtX95O1eK/NM6m8wjzUmild7ufB8gcLik4=";
  };

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
    gobject-introspection
    librsvg
  ];

  buildInputs = [
    gtk4
    libadwaita
    glib
    libsecret
  ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/shini4i/openfortivpn-gui/internal/ui.Version=${version}"
    "-X main.version=${version}"
  ];

  # Build both the GUI and the helper daemon
  subPackages = [
    "cmd/openfortivpn-gui"
    "cmd/openfortivpn-gui-helper"
  ];

  # CGO builds with gotk4 GTK4 bindings retain references to Go toolchain
  # due to runtime type information embedded by the bindings.
  allowGoReference = true;

  postInstall = ''
    # Install the desktop file
    install -Dm644 $src/data/com.github.shini4i.openfortivpn-gui.desktop \
      $out/share/applications/com.github.shini4i.openfortivpn-gui.desktop

    # Convert and install the icon to hicolor theme
    for size in 16 24 32 48 64 128 256 512; do
      install -d $out/share/icons/hicolor/''${size}x''${size}/apps
      rsvg-convert -w $size -h $size ${icon} \
        -o $out/share/icons/hicolor/''${size}x''${size}/apps/openfortivpn-gui.png
    done

    # Install SVG icon for scalable
    install -Dm644 ${icon} \
      $out/share/icons/hicolor/scalable/apps/openfortivpn-gui.svg

    # Install the systemd service file for the helper daemon.
    # Note: NixOS users should use the nixosModules.openfortivpn-gui-helper module
    # instead, which creates a properly configured service with Nix store paths.
    # This file is provided for non-NixOS Linux distributions.
    install -Dm644 $src/data/openfortivpn-gui-helper.service \
      $out/lib/systemd/system/openfortivpn-gui-helper.service
  '';

  # Update the desktop file to use our icon
  postFixup = ''
    substituteInPlace $out/share/applications/com.github.shini4i.openfortivpn-gui.desktop \
      --replace-fail "Icon=network-vpn" "Icon=openfortivpn-gui"
  '';

  # Add openfortivpn to PATH via GApps wrapper (more idiomatic than separate wrapProgram)
  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ openfortivpn ]})
  '';

  meta = with lib; {
    description = "GTK4/libadwaita GUI client for Fortinet SSL VPN with helper daemon";
    longDescription = ''
      A modern GTK4/libadwaita GUI client for Fortinet SSL VPN on Linux,
      wrapping the openfortivpn CLI tool. Features include multiple VPN
      profiles, various authentication methods (password, OTP, certificate,
      SAML/SSO), system tray integration, secure credential storage in
      system keyring, and configurable routing options.

      This package also includes openfortivpn-gui-helper, a privileged helper
      daemon that eliminates password prompts for VPN operations. The daemon
      runs as a systemd service with root privileges, communicating with the
      GUI via a UNIX socket.
    '';
    homepage = "https://github.com/shini4i/openfortivpn-gui";
    license = licenses.gpl3Only;
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "openfortivpn-gui";
  };
}
