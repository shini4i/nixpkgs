# Package index
# Add new packages here using callPackage.
# Packages whose meta.platforms excludes the host system are omitted,
# so `nix flake check` does not evaluate them on unsupported systems.
{
  pkgs,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
}:

let
  allPackages = {
    argo-compare = pkgs.callPackage ./argo-compare { };
    asd-brightness-daemon = pkgs.callPackage ./asd-brightness-daemon { };
    brave = pkgs.callPackage ./brave { };
    gnome-shell-extension-apple-studio-display =
      pkgs.callPackage ./gnome-shell-extension-apple-studio-display
        { };
    gnome-shell-extension-elgato-lights = pkgs.callPackage ./gnome-shell-extension-elgato-lights { };
    kd = pkgs.callPackage ./kd { };
    kubeseal-auto = pkgs.callPackage ./kubeseal-auto {
      inherit uv2nix pyproject-nix pyproject-build-systems;
    };
    openfortivpn-gui = pkgs.callPackage ./openfortivpn-gui { };
    pam-lid-block = pkgs.callPackage ./pam-lid-block { };
  };
in
pkgs.lib.filterAttrs (_: pkg: pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform pkg) allPackages
