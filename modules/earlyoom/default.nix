# services.earlyoom.enable = true;
{ config, lib, ... }:

let

  cfg = config.services.earlyoom;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    services.earlyoom = {
      freeSwapThreshold = 10; # % default
      freeMemThreshold = 10; # % default
      extraArgs = [ 
        "-g" 
        # "--avoid '^(Hyprland|kitty)$'"
        # "--prefer '^(chromium|firefox|electron|libreoffice|gimp)$'"
      ];
     };

   };
}

