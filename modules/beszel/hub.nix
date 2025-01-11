# services.beszel.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.services.beszel;
  inherit (builtins) toString;
  inherit (lib) mkIf mkEnableOption mkOption types;
  port = 8090;

in {

  options.services.beszel.enable = mkEnableOption "Beszel hub";

  config = mkIf cfg.enable {

    file."${cfg.dataDir}/hub" = {
      type = "dir"; 
      mode = 775; 
      user = "beszel";
      group = "beszel";
    };

    systemd.services.beszel-hub = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "beszel";
        Group = "beszel";
        Restart = "always";
        WorkingDirectory = "${cfg.dataDir}/hub";
        ExecStart = "${cfg.package}/bin/beszel-hub serve --http '0.0.0.0:${toString port}'";
        startLimitInterval = 180;
        startLimitBurst = 30;
        RestartSec = "5";
      };
    };

    services.traefik.proxy."beszel" = "http://127.0.0.1:${toString port}";

  };

}
