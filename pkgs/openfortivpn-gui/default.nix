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
  pkg-config,
  wrapGAppsHook4,
  gobject-introspection,
  gtk4,
  libadwaita,
  glib,
  libsecret,
  openfortivpn,
}:

buildGoModule rec {
  pname = "openfortivpn-gui";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "shini4i";
    repo = "openfortivpn-gui";
    rev = "v0.4.1";
    hash = "sha256-MududdZ8EJBrK5TA+ex0Gnm0GEbs5d0rxdIyQOik17M=";
  };

  vendorHash = "sha256-MFVIe0h0fc2doBRcPtuBWgPNpLl06BwNN9wB5JQOt7k=";

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
    gobject-introspection
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

    # Install the application icons shipped upstream (XDG hicolor theme).
    # The .desktop entry's Icon=openfortivpn-gui resolves against these.
    for size in 16 24 32 48 64 96 128 256 512; do
      install -Dm644 $src/assets/icons/hicolor/''${size}x''${size}/apps/openfortivpn-gui.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/openfortivpn-gui.png
    done

    # Install the systemd service file for the helper daemon.
    # Note: NixOS users should use the nixosModules.openfortivpn-gui-helper module
    # instead, which creates a properly configured service with Nix store paths.
    # This file is provided for non-NixOS Linux distributions.
    install -Dm644 $src/data/openfortivpn-gui-helper.service \
      $out/lib/systemd/system/openfortivpn-gui-helper.service
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
