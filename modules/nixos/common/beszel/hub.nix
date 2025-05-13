# services.beszel.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.services.beszel;
  inherit (builtins) toString;
  inherit (lib) mkIf mkEnableOption mkOption types;
  port = 8090;

in {

  options.services.beszel.enable = mkEnableOption "Beszel hub";

  config = mkIf cfg.enable {

    tmpfiles.directories = [{
      target = "${cfg.dataDir}/hub";
      user = "beszel";
    }];

    systemd.services.beszel-hub = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "beszel";
        Group = "beszel";
        Restart = "always";
        WorkingDirectory = "${cfg.dataDir}/hub";
        ExecStart = "${cfg.package}/bin/beszel-hub serve --http '0.0.0.0:${toString port}'";
        RestartSec = "5";
      };
      startLimitIntervalSec = 180;
      startLimitBurst = 30;
    };

    services.traefik.proxy."beszel" = port;

  };

}
