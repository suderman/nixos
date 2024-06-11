# services.keyd.enable = true;
{ config, lib, pkgs, this, ... }: let 

  cfg = config.services.keyd;
  ini = pkgs.formats.ini {};
  inherit (lib) mkDefault mkIf mkOption types;
  inherit (this.lib) mkShellScript;

in {

  options.services.keyd = {
    enable = lib.options.mkEnableOption "keyd"; 
    systemdTarget = mkOption {
      type = types.str;
      default = "";
    };
    applications = mkOption {
      type = types.anything;
      default = {};
    };
  };

  # Configuration for each application
  config.xdg.configFile = {
    "keyd/app.conf".source = ini.generate "app.conf" ( {

      # [geary]
      # [telegramdesktop]
      # [fluffychat]
      # [gimp-2-9]
      # [obsidian]
      # [slack]

    } // cfg.applications );

  };

  # User service runs keyd-application-mapper
  config.systemd.user.services = (if cfg.systemdTarget == "" then {} else {
    keyd.Unit = {
      Description = "Keyd Application Mapper";
      After = [ cfg.systemdTarget ];
      Requires = [ cfg.systemdTarget ];
    };
    keyd.Install.WantedBy = [ cfg.systemdTarget ];
    keyd.Service = {
      Type = "simple";
      Restart = "always";
      ExecStart = mkShellScript {
        inputs = [ pkgs.keyd ];
        text = "keyd-application-mapper";
      };
    };
  });

}
