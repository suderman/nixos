# -- custom module --
# programs.home-assistant.enable = true;
{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.programs.home-assistant;
  inherit (lib) mkIf mkOption options types;
  inherit (config.programs.chromium.lib) mkClass mkWebApp;
in {
  options.programs.home-assistant = {
    enable = options.mkEnableOption "home-assistant";
    url = mkOption {
      type = types.str;
      default = "http://hass";
    };
  };

  config = mkIf cfg.enable {
    # Web App
    xdg.desktopEntries =
      mkWebApp {
        name = "Home Assistant";
        icon = ./home-assistant.svg;
        inherit (cfg) url;
      }
      // {
        # ISY Java applet
        isy = {
          name = "ISY";
          icon = ./isy.png;
          exec = "isy %U";
          terminal = false;
          categories = ["Application"];
        };
      };

    # Keyboard shortcuts
    services.keyd.windows = {
      "${mkClass cfg.url}" = {};
    };

    # isy launcher
    home.packages = [perSystem.self.isy];
  };
}
