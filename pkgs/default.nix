# Package index
# Add new packages here using callPackage
{ pkgs, p2nix }:

{
  argo-compare = pkgs.callPackage ./argo-compare { };
  kd = pkgs.callPackage ./kd { };
  kubeseal-auto = pkgs.callPackage ./kubeseal-auto { inherit p2nix; };
  gnome-shell-extension-elgato-lights = pkgs.callPackage ./gnome-shell-extension-elgato-lights { };
}
