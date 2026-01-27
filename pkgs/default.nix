# Package index
# Add new packages here using callPackage
{ pkgs, p2nix }:

{
  argo-compare = pkgs.callPackage ./argo-compare { };
  asd-brightness-daemon = pkgs.callPackage ./asd-brightness-daemon { };
  gnome-shell-extension-apple-studio-display = pkgs.callPackage ./gnome-shell-extension-apple-studio-display { };
  gnome-shell-extension-elgato-lights = pkgs.callPackage ./gnome-shell-extension-elgato-lights { };
  kd = pkgs.callPackage ./kd { };
  kubeseal-auto = pkgs.callPackage ./kubeseal-auto { inherit p2nix; };
  openfortivpn-gui = pkgs.callPackage ./openfortivpn-gui { };
  pam-lid-block = pkgs.callPackage ./pam-lid-block { };
}
