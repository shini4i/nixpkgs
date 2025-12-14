# Package index
# Add new packages here using callPackage
{ pkgs, p2nix }:

{
  kd = pkgs.callPackage ./kd { };
  kubeseal-auto = pkgs.callPackage ./kubeseal-auto { inherit p2nix; };
}
