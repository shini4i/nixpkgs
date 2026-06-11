{
  description = "Custom Nix packages and NixOS modules collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # uv2nix toolchain for building kubeseal-auto from its uv.lock.
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, pyproject-nix, uv2nix, pyproject-build-systems }:
    let
      # Systems to support
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Helper to generate attributes for each system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for each system
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      # Packages for each system
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          customPkgs = import ./pkgs {
            inherit pkgs uv2nix pyproject-nix pyproject-build-systems;
          };
        in
        customPkgs
      );

      # For `nix flake check`
      checks = forAllSystems (system:
        let
          packages = self.packages.${system};
        in
        packages
      );

      # Development shell with tools
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              go-task
              nixfmt-rfc-style
            ];
          };
        }
      );

      # NixOS modules for service configuration
      nixosModules = {
        apple-studio-display =
          { lib, pkgs, ... }:
          {
            imports = [ ./modules/apple-studio-display.nix ];

            # Inject the flake's packages as defaults
            programs.apple-studio-display.daemonPackage = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.asd-brightness-daemon;
            programs.apple-studio-display.extensionPackage = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.gnome-shell-extension-apple-studio-display;
          };

        openfortivpn-gui =
          { lib, pkgs, ... }:
          {
            imports = [ ./modules/openfortivpn-gui.nix ];

            # Inject the flake's package as default
            programs.openfortivpn-gui.package = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.openfortivpn-gui;
          };
      };
    };
}
