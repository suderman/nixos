# services.beszel.enableAgent = true;
{ config, lib, pkgs, ... }: let

  cfg = config.services.beszel;
  inherit (builtins) toString;
  inherit (lib) mkIf mkOption types;

in {

  options.services.beszel = {
    key = mkOption {
      type = types.str;
      description = "Beszel hub public key";
      default = "";
    };
    enableAgent = mkOption {
      type = types.bool;
      description = "Enable beszel agent";
      default = if cfg.key == "" then false else true;
    };
    agentPort = mkOption {
      type = types.port;
      default = 45876; 
    };
  };

  config = mkIf cfg.enableAgent {

    file."${cfg.dataDir}/agent" = {
      type = "dir"; 
      mode = 775; 
      user = "beszel";
      group = "beszel";
    };

    systemd.services.beszel-agent = {
      wantedBy = [ "multi-user.target" ];
      environment = {
        PORT = toString cfg.agentPort;
        KEY = cfg.key;
      };
      serviceConfig = {
        User = "beszel";
        Group = "beszel";
        Restart = "always";
        WorkingDirectory = "${cfg.dataDir}/agent";
        ExecStart = "${cfg.package}/bin/beszel-agent";
        startLimitInterval = 180;
        startLimitBurst = 30;
        RestartSec = "5";
      };
    };
    
    networking.firewall.allowedTCPPorts = [ cfg.agentPort ];

  };

}
