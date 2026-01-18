{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  hidapi,
  libusb1,
  systemdLibs,
}:
/**
  * @name pkgs/asd-brightness-daemon/default.nix
  * @description D-Bus service for Apple Studio Display brightness control.
  * Provides a session D-Bus service (io.github.shini4i.AsdBrightness) that
  * communicates with Apple Studio Display via USB HID to control brightness.
  * Includes udev monitoring for hot-plug support.
  */
buildGoModule rec {
  pname = "asd-brightness-daemon";
  version = "0.1.0-unstable-2026-01-18";

  src = fetchFromGitHub {
    owner = "shini4i";
    repo = "gnome-shell-extension-apple-studio-display";
    rev = "ca0d13109c2c5194d1b3f83fecc3f90e9ae2a97b";
    hash = "sha256-6kWQgTebQcfrriqUSeQPZjhj/aRsFLww0bmyxn6LQSI=";
  };

  vendorHash = "sha256-YHVtm/lW3OV3qWFUVH//bsLsxTdzMAYN3F8lUwsKpsU=";

  # The Go module is in the daemon subdirectory
  modRoot = "daemon";

  # Build only the daemon binary
  subPackages = [ "cmd/asd-brightness-daemon" ];

  # CGO is required for karalabe/hid (USB HID) and pilebones/go-udev
  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    hidapi
    libusb1
    systemdLibs # For libudev (go-udev)
  ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with lib; {
    description = "D-Bus daemon for Apple Studio Display brightness control via USB HID";
    longDescription = ''
      A D-Bus service that provides brightness control for Apple Studio Display
      monitors. Communicates with the display via USB HID feature reports and
      exposes a session bus interface (io.github.shini4i.AsdBrightness) for the
      GNOME Shell extension to control brightness levels.

      Features include:
      - Per-display brightness control
      - Hot-plug detection via udev
      - Automatic display discovery
    '';
    homepage = "https://github.com/shini4i/gnome-shell-extension-apple-studio-display";
    license = licenses.gpl3Only;
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "asd-brightness-daemon";
  };
}
