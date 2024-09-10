# programs.immich.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.immich;
  inherit (lib) mkIf mkOption options types;
  inherit (config.programs.chromium.lib) mkClass mkWebApp;

in {

  options.programs.immich = {
    enable = options.mkEnableOption "immich"; 
    url = mkOption { type = types.str; default = "http://immich"; };
    platform = mkOption { type = types.str; default = "wayland"; };
  };

  config = mkIf cfg.enable {

    # Web App
    xdg.desktopEntries = mkWebApp {
      name = "Immich";
      icon = ./immich.png; 
      inherit (cfg) url platform;
    };

    # Keyboard shortcuts
    services.keyd.windows = {
      "${mkClass cfg.url}" = {};
    };

    # cli upload tools
    home.packages = with pkgs; [ 
      immich-cli
      immich-go
    ];

  };

}
