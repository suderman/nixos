{ lib, packages ? [], betaPackages ? [], ... }: let

  allPackages = packages ++ betaPackages;
  hasPackages = length allPackages > 0;
  inherit (lib) length mkOption types;

in {

  # Automatically enable if any packages are in list
  enable = mkOption { type = types.bool; default = hasPackages; };

  # Stabe and beta packages
  packages = mkOption { type = with types; (listOf str); default = []; }; 
  betaPackages = mkOption { type = with types; (listOf str); default = []; }; 

  # Combined packages
  allPackages = mkOption { type = with types; (listOf str); readOnly = true; default = allPackages; }; 

}
