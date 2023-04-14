# modules.earlyoom.enable = true;
{ config, lib, ... }:

let

  cfg = config.modules.earlyoom;
  inherit (lib) mkIf;

in {

  options.modules.earlyoom = {
    enable = lib.options.mkEnableOption "earlyoom"; 
  };

  config = mkIf cfg.enable {

    services.earlyoom = {
      enable = true;
      freeSwapThreshold = 10; # % default
      freeMemThreshold = 10; # % default
      extraArgs = [
          "-g" "--avoid '^(X|plasma.*|konsole|kwin)$'"
          "--prefer '^(electron|libreoffice|gimp)$'"
        ];
     };

   };
}

