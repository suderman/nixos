# services.keyd.enable = true;
{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.services.keyd;
  ini = pkgs.formats.ini {};
  inherit (perSystem.self) mkScript;
  inherit (config.lib.keyd) expandHomeRowModifierRules;
  inherit (lib) mkOption types;
  expandedWindows = expandHomeRowModifierRules cfg.windows;
in {
  # Import keyd lib
  imports = [./lib.nix];

  options.services.keyd = {
    enable = lib.options.mkEnableOption "keyd";
    systemdTarget = mkOption {
      type = types.str;
      default = "";
    };
    mapper.enable = mkOption {
      type = types.bool;
      default = true;
    };
    windows = mkOption {
      type = types.anything;
      default = {}; # firefox = { "alt.f" = "C-f"; };
    };
    layers = mkOption {
      type = types.anything;
      default = {}; # rofi = { "super.j" = "down"; };
    };
  };

  # Configuration for each application
  config.xdg.configFile = {
    "keyd/app.conf".source = ini.generate "app.conf" ({
        # [geary]
        # [telegramdesktop]
        # [fluffychat]
        # [gimp-2-9]
        # [obsidian]
        # [slack]
      }
      // expandedWindows);
  };

  # User service runs keyd-application-mapper.
  config.systemd.user.services =
    if cfg.systemdTarget == "" || !cfg.mapper.enable
    then {}
    else {
      keyd.Unit = {
        Description = "Keyd Application Mapper";
        After = [cfg.systemdTarget];
        Requires = [cfg.systemdTarget];
      };
      keyd.Install.WantedBy = [cfg.systemdTarget];
      keyd.Service = {
        Type = "simple";
        Restart = "always";
        ExecStart = mkScript {
          path = [pkgs.keyd];
          text = "keyd-application-mapper";
        };
      };
    };
}
