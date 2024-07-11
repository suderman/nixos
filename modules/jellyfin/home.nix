# programs.jellyfin.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.jellyfin;
  inherit (lib) mkIf mkOption options types;
  inherit (config.programs.chromium.lib) mkClass mkWebApp;

in {

  options.programs.jellyfin = {
    enable = options.mkEnableOption "jellyfin"; 
    url = mkOption { type = types.str; default = "http://jellyfin"; };
    platform = mkOption { type = types.str; default = "wayland"; };
  };

  config = mkIf cfg.enable {

    # Web App
    xdg.desktopEntries = mkWebApp {
      name = "Jellyfin";
      icon = ./jellyfin.svg; 
      inherit (cfg) url platform;
    };

    # Keyboard shortcuts
    services.keyd.windows = {
      "${mkClass cfg.url}" = {
        "super.[" = "A-left"; # back
        "super.]" = "A-right"; # forward
      };
    };

  };

}
