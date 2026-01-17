# NixOS module for Apple Studio Display brightness control
#
# Provides GNOME Shell extension and D-Bus daemon for controlling brightness
# of Apple Studio Display monitors via USB HID.
#
# Usage:
#   programs.apple-studio-display = {
#     enable = true;  # Installs extension and enables daemon
#   };
#
# The extension will appear in GNOME Quick Settings when an Apple Studio
# Display is connected.
#
# Note: Users must be in the "video" group to access display devices.
# This follows NixOS conventions for brightness control (see programs.light).
# Example: users.users.<username>.extraGroups = [ "video" ];
#
# Note: This module is designed to be used via the flake's nixosModules.
# The packages are automatically injected by the flake wrapper.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.apple-studio-display;
in
{
  options.programs.apple-studio-display = {
    enable = lib.mkEnableOption "Apple Studio Display brightness control";

    daemonPackage = lib.mkOption {
      type = lib.types.package;
      description = ''
        The asd-brightness-daemon package to use.

        When importing via the flake's nixosModules.apple-studio-display, this is
        automatically set to the flake's package. When importing the module
        directly, this option must be set explicitly.
      '';
      example = lib.literalExpression "pkgs.asd-brightness-daemon";
    };

    extensionPackage = lib.mkOption {
      type = lib.types.package;
      description = ''
        The gnome-shell-extension-apple-studio-display package to use.

        When importing via the flake's nixosModules.apple-studio-display, this is
        automatically set to the flake's package. When importing the module
        directly, this option must be set explicitly.
      '';
      example = lib.literalExpression "pkgs.gnome-shell-extension-apple-studio-display";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install the GNOME Shell extension
    environment.systemPackages = [ cfg.extensionPackage ];

    # udev rules for Apple Studio Display USB access
    # VendorID: 0x05ac (Apple), ProductID: 0x1114 (Studio Display)
    # Note: Uses SUBSYSTEM=="usb" because the daemon's HID library (karalabe/hid)
    # uses the libusb backend, accessing /dev/bus/usb/* instead of /dev/hidraw*
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="05ac", ATTR{idProduct}=="1114", GROUP="video", MODE="0660"
    '';

    # Systemd user service for the D-Bus daemon
    systemd.user.services.asd-brightness = {
      description = "Apple Studio Display Brightness D-Bus Service";
      documentation = [ "https://github.com/shini4i/gnome-shell-extension-apple-studio-display" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];

      serviceConfig = {
        Type = "dbus";
        BusName = "io.github.shini4i.AsdBrightness";
        ExecStart = "${lib.getExe cfg.daemonPackage}";
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;

        # Device access - requires access to USB devices for libusb backend
        # Using DevicePolicy=auto to support hot-plug: with "closed", the cgroup
        # tracks devices by major:minor numbers which change on USB reconnection,
        # causing the daemon to lose access until restart. "auto" allows dynamic
        # device access while udev rules still restrict permissions to video group.
        PrivateDevices = false;
        DevicePolicy = "auto";

        # Additional hardening
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        ProtectClock = true;

        # AF_UNIX for D-Bus IPC, AF_NETLINK for udev hot-plug monitoring
        RestrictAddressFamilies = [ "AF_UNIX" "AF_NETLINK" ];

        # Capability restrictions - no elevated privileges needed
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
      };
    };
  };
}
