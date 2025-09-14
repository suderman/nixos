# services.beszel.enableAgent = true;
{
  config,
  lib,
  flake,
  ...
}: let
  cfg = config.services.beszel;
  inherit (builtins) toString;
  inherit (lib) mkIf mkOption types;
in {
  options.services.beszel = {
    key = mkOption {
      type = types.str;
      description = "Beszel hub public key";
      default = let
        inherit (builtins) pathExists readFile;
        sshPub = flake + /users/beszel/id_ed25519.pub;
      in
        if pathExists sshPub
        then readFile sshPub
        else "";
    };
    enableAgent = mkOption {
      type = types.bool;
      description = "Enable beszel agent";
      default =
        if cfg.key == ""
        then false
        else true;
    };
    agentPort = mkOption {
      type = types.port;
      default = 45876;
    };
    extraPackages = mkOption {
      type = with types; listOf package;
      default = [];
    };
  };

  config = mkIf cfg.enableAgent {
    # tmpfiles.directories = [{
    #   target = "${cfg.dataDir}/agent";
    #   user = "beszel";
    # }];

    systemd.services.beszel-agent = {
      wantedBy = ["multi-user.target"];
      environment = {
        PORT = toString cfg.agentPort;
        KEY = cfg.key;
      };
      path = cfg.extraPackages;
      serviceConfig = {
        User = "beszel";
        Group = "beszel";
        Restart = "always";
        # WorkingDirectory = "${cfg.dataDir}/agent";
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/beszel-agent";
        RestartSec = "5";
      };
      startLimitIntervalSec = 180;
      startLimitBurst = 30;
    };

    networking.firewall.allowedTCPPorts = [cfg.agentPort];
  };
}
