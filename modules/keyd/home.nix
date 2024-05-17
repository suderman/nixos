# modules.keyd.enable = true;
{ config, lib, pkgs, this, ... }: let 

  cfg = config.modules.keyd;
  ini = pkgs.formats.ini {};
  inherit (lib) mkIf mkOption types;
  inherit (this.lib) mkShellScript;

in {

  options.modules.keyd = {
    enable = lib.options.mkEnableOption "keyd"; 
    service = lib.options.mkEnableOption "keyd-application-mapper"; 
    applications = mkOption {
      type = types.anything;
      default = {};
    };
  };

  config = mkIf cfg.enable {

    # Configuration for each application
    xdg.configFile = {
      "keyd/app.conf".source = ini.generate "app.conf" ( {

        "*" = {
          "meta.a" = "C-a";
          "meta.z" = "C-z";
        };

        firefox = {
          "alt.f" = "C-f";
          "alt.l" = "C-l";
        };

        org-gnome-nautilus = {
          "alt.enter" = "f2";
          "alt.r" = "f2";
          "alt.i" = "C-i";
        };

        # [geary]
        # [telegramdesktop]
        # [1password]
        # [fluffychat]
        # [gimp-2-9]
        # [obsidian]
        # [slack]

      } // cfg.applications );

    };

    # User service runs keyd-application-mapper
    systemd.user.services = mkIf cfg.service {
      keyd.Unit = {
        Description = "Keyd Application Mapper";
        After = [ "graphical-session.target" ];
        Requires = [ "graphical-session.target" ];
      };
      keyd.Install.WantedBy = [ "default.target" ];
      keyd.Service = {
        Type = "simple";
        Restart = "always";
        ExecStart = mkShellScript {
          inputs = [ pkgs.keyd ];
          text = "keyd-application-mapper";
        };
      };
    };

  };

}
