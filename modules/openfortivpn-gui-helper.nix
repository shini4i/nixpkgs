# NixOS module for openfortivpn-gui-helper daemon
#
# The helper daemon runs as a systemd service with root privileges and handles
# VPN connection management on behalf of unprivileged GUI clients. Communication
# happens over a UNIX socket using JSON messages.
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
  cfg = config.services.openfortivpn-gui-helper;
in
{
  options.services.openfortivpn-gui-helper = {
    enable = lib.mkEnableOption "OpenFortiVPN GUI helper daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.openfortivpn-gui;
      defaultText = lib.literalExpression "pkgs.openfortivpn-gui";
      description = "The openfortivpn-gui package to use (contains the helper binary).";
    };

    openfortivpnPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.openfortivpn;
      defaultText = lib.literalExpression "pkgs.openfortivpn";
      description = "The openfortivpn package to use for VPN connections.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "openfortivpn-gui";
      description = ''
        Group that can access the helper daemon socket.
        Users must be added to this group to use the helper daemon.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Create the group for socket access control
    users.groups.${cfg.group} = { };

    # Systemd service configuration
    systemd.services.openfortivpn-gui-helper = {
      description = "OpenFortiVPN GUI Helper Daemon";
      documentation = [ "https://github.com/shini4i/openfortivpn-gui" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "notify";
        ExecStart = "${lib.getExe' cfg.package "openfortivpn-gui-helper"} --openfortivpn ${lib.getExe cfg.openfortivpnPackage}";
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
            chown root:${cfg.group} /run/openfortivpn-gui/helper.sock
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
