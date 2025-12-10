# Overlay for integrating custom packages into nixpkgs
# Usage: nixpkgs.overlays = [ shini4i-pkgs.overlays.default ];
final: prev:

let
  customPkgs = import ./pkgs { pkgs = final; };
in
customPkgs
