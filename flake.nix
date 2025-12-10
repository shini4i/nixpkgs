{
  description = "Custom Nix packages collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
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
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      });
    in
    {
      # Overlay for use in other flakes
      overlays.default = import ./overlay.nix;

      # Packages for each system
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          customPkgs = import ./pkgs { inherit pkgs; };
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
    };
}
