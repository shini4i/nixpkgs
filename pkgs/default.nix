# Package index
# Add new packages here using callPackage
{ pkgs }:

{
  kd = pkgs.callPackage ./kd { };
  kubeseal-auto = pkgs.callPackage ./kubeseal-auto { };
}
