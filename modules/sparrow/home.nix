# programs.sparrow.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.sparrow;
  inherit (lib) mkIf mkOption types getExe mkShellScript;
  inherit (builtins) toString;
  inherit (config.services.keyd.lib) mkClass;

  # Window class name
  class = "Sparrow";

in {

  options.programs.sparrow = {
    enable = lib.options.mkEnableOption "sparrow"; 
    scale = mkOption { type = types.float; default = 1.5; };
  };

  config = mkIf cfg.enable {

    home.packages = [ pkgs.sparrow ];

    xdg.desktopEntries = let 

      sparrow-desktop-wrapper = mkShellScript {
        name = "sparrow-desktop-wrapper";
        text = ''
          JAVA_TOOL_OPTIONS="-Dglass.gtk.uiScale=${toString cfg.scale}" ${getExe pkgs.sparrow} 
        '';
      };

    in {

      "sparrow-desktop" = {
        name = "Sparrow Bitcoin Wallet"; 
        genericName = "Bitcoin Wallet";
        icon = "sparrow-desktop"; 
        terminal = false;
        type = "Application";
        exec = "${getExe sparrow-desktop-wrapper}";
      };
    };

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {
      "super.w" = "C-w"; # close
    };

    # no blur on context menus (runs in xwayland)
    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [
        "noblur,class:^${class}$,title:^()$"
      ];
    };

  };

}
