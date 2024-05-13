# modules.keyd.enable = true;
{ config, lib, pkgs, ... }: 

with pkgs; 

let 
  cfg = config.modules.keyd;
  inherit (lib) mkIf;
  inherit (this.lib) mkShellScript;

in {
  options = {
    modules.keyd.enable = lib.options.mkEnableOption "keyd"; 
  };

  config = mkIf cfg.enable {

    # User service runs keyd-application-mapper
    systemd.user.services.keyd = {
      Unit = {
        Description = "Keyd Application Mapper";
        After = [ "graphical-session.target" ];
        Requires = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        Type = "simple";
        Restart = "always";
        ExecStart = mkShellScript {
          inputs = [ pkgs.keyd ];
          text = "keyd-application-mapper";
        };
      };
    };

    # Configuration for each application
    xdg.configFile = {
      "keyd/app.conf".text = builtins.readFile ./app.conf;
    };

  };

}
