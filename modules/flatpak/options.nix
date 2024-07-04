{ lib, apps ? [], beta ? [], ... }: let

  all = apps ++ beta;
  inherit (lib) mkOption types;

in {

  # Stable and beta packages
  apps = mkOption { type = with types; (listOf str); default = []; }; 
  beta = mkOption { type = with types; (listOf str); default = []; }; 

  # Combined packages
  all = mkOption { type = with types; (listOf str); readOnly = true; default = all; }; 

}
