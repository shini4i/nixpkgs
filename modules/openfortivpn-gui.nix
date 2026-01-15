# NixOS module for openfortivpn-gui
#
# Provides a GTK4/libadwaita GUI client for Fortinet SSL VPN with an optional
# privileged helper daemon for passwordless VPN operations.
#
# Usage:
#   programs.openfortivpn-gui = {
#     enable = true;          # Installs the GUI application
#     helper.enable = true;   # Enables the helper daemon (optional)
#   };
#
# Users must be added to the configured group to access the helper daemon:
#   users.users.youruser.extraGroups = [ "openfortivpn-gui" ];
#
# Security Note: There is a brief window between socket creation and permission
# setting where the socket may be accessible. For production environments,
# consider modifying the daemon to support socket activation or to accept
# socket permission arguments directly.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.openfortivpn-gui;
in
{
  options.programs.openfortivpn-gui = {
    enable = lib.mkEnableOption "OpenFortiVPN GUI client";

    package = lib.mkOption {
      type = lib.types.package;
      description = ''
        The openfortivpn-gui package to use.

        When importing via the flake's nixosModules.openfortivpn-gui, this is
        automatically set to the flake's package. When importing the module
        directly, this option must be set explicitly.
      '';
      example = lib.literalExpression "pkgs.openfortivpn-gui";
    };

    helper = {
      enable = lib.mkEnableOption "OpenFortiVPN GUI helper daemon for passwordless VPN operations";

      openfortivpnPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.openfortivpn;
        defaultText = lib.literalExpression "pkgs.openfortivpn";
        description = "The openfortivpn package to use for VPN connections.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "openfortivpn-gui";
        example = "vpn-users";
        description = ''
          Group that can access the helper daemon socket.
          Users must be added to this group to use the helper daemon.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Install the GUI application
    environment.systemPackages = [ cfg.package ];

    # Helper daemon configuration (optional)
    users.groups.${cfg.helper.group} = lib.mkIf cfg.helper.enable { };

    systemd.services.openfortivpn-gui-helper = lib.mkIf cfg.helper.enable {
      description = "OpenFortiVPN GUI Helper Daemon";
      documentation = [ "https://github.com/shini4i/openfortivpn-gui" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "notify";
        ExecStart = "${lib.getExe' cfg.package "openfortivpn-gui-helper"} --openfortivpn ${lib.getExe cfg.helper.openfortivpnPackage}";
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening
        # NoNewPrivileges must be false because openfortivpn needs to create TUN devices
        NoNewPrivileges = false;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;

        # Additional hardening options
        PrivateDevices = false; # Needs access to /dev/net/tun
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";

        # Restrict network socket types (needs UNIX for IPC, INET/INET6 for VPN, NETLINK for routing)
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];

        # Runtime directory for socket
        RuntimeDirectory = "openfortivpn-gui";
        RuntimeDirectoryMode = "0755";

        # State directory
        StateDirectory = "openfortivpn-gui";
        StateDirectoryMode = "0755";

        # Watchdog for service health monitoring
        WatchdogSec = 30;
      };

      # Set socket permissions after service starts.
      # The daemon creates the socket with default permissions, so we need
      # to adjust group ownership and mode after creation.
      # Note: There is a brief race window here. For improved security,
      # the daemon should be modified to support socket activation.
      postStart = ''
        for i in $(seq 1 50); do
          if [ -S /run/openfortivpn-gui/helper.sock ]; then
            chown root:${cfg.helper.group} /run/openfortivpn-gui/helper.sock
            chmod 0660 /run/openfortivpn-gui/helper.sock
            exit 0
          fi
          sleep 0.1
        done
        echo "Socket was not created within 5 seconds" >&2
        exit 1
      '';
    };
  };
}
