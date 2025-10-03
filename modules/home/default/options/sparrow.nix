# programs.sparrow.enable = true;
{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.programs.sparrow;
  inherit (lib) mkIf mkOption types getExe;
  inherit (config.services.keyd.lib) mkClass;
  dataDir = ".config/sparrow";

  # Window class name
  class = "Sparrow";
in {
  options.programs.sparrow = {
    enable = lib.options.mkEnableOption "sparrow";
    scale = mkOption {
      type = types.float;
      default = 1.5;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.sparrow;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.sparrow];

    xdg.desktopEntries = let
      sparrow-desktop-wrapper = perSystem.self.mkScript {
        name = "sparrow-desktop-wrapper";
        text = toString [
          "JAVA_TOOL_OPTIONS=\"-Dglass.gtk.uiScale=${toString cfg.scale}\""
          "${getExe cfg.package}"
          "-d ${config.home.homeDirectory}/${dataDir}"
        ];
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

    # Persist data between reboots
    persist.storage.directories = [dataDir];

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {
      "super.w" = "C-w"; # close
    };

    # no blur on context menus (runs in xwayland)
    wayland.windowManager.hyprland.settings = {
      windowrule = [
        "noblur,class:^${class}$,title:^()$"
      ];
    };
  };
}
