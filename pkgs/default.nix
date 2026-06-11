# Package index
# Add new packages here using callPackage
{ pkgs, uv2nix, pyproject-nix, pyproject-build-systems }:

{
  argo-compare = pkgs.callPackage ./argo-compare { };
  asd-brightness-daemon = pkgs.callPackage ./asd-brightness-daemon { };
  gnome-shell-extension-apple-studio-display = pkgs.callPackage ./gnome-shell-extension-apple-studio-display { };
  gnome-shell-extension-elgato-lights = pkgs.callPackage ./gnome-shell-extension-elgato-lights { };
  kd = pkgs.callPackage ./kd { };
  kubeseal-auto = pkgs.callPackage ./kubeseal-auto {
    inherit uv2nix pyproject-nix pyproject-build-systems;
  };
  openfortivpn-gui = pkgs.callPackage ./openfortivpn-gui { };
  pam-lid-block = pkgs.callPackage ./pam-lid-block { };
}
