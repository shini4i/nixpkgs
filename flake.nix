{
  description = "Custom Nix packages and NixOS modules collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, poetry2nix }:
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

      # poetry2nix instantiated for each system
      poetry2nixFor = forAllSystems (system:
        poetry2nix.lib.mkPoetry2Nix { pkgs = nixpkgsFor.${system}; }
      );
    in
    {
      # Packages for each system
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          p2nix = poetry2nixFor.${system};
          customPkgs = import ./pkgs { inherit pkgs p2nix; };
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
        openfortivpn-gui-helper = ./modules/openfortivpn-gui-helper.nix;
      };
    };
}
