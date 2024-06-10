# services.keyd.enable = true;
{ config, lib, pkgs, this, ... }: let 

  cfg = config.services.keyd;
  ini = pkgs.formats.ini {};
  inherit (lib) mkDefault mkIf mkOption types;
  inherit (this.lib) mkShellScript;

in {

  options.services.keyd = {
    enable = lib.options.mkEnableOption "keyd"; 
    applications = mkOption {
      type = types.anything;
      default = {};
    };
  };

  # Configuration for each application
  config.xdg.configFile = {
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
  config.systemd.user.services = mkIf cfg.enable {
    keyd.Unit = {
      Description = "Keyd Application Mapper";
      After = mkDefault [ "graphical-session.target" ];
      Requires = mkDefault [ "graphical-session.target" ];
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

}
