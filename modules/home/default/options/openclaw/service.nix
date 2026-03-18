# config.services.openclaw.enable = true;
{
  config,
  lib,
  ...
}: let
  srv = config.services.openclaw;
  inherit (config.lib.openclaw) path port;
in {
  options.services.openclaw = {
    enable = lib.mkEnableOption "openclaw";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = ".openclaw";
    };
    # probably shouldn't have to change this
    name = lib.mkOption {
      type = lib.types.str;
      default = "openclaw-${config.home.username}";
      example = "openclaw-jon";
    };
    # automatically derived
    port = lib.mkOption {
      type = lib.types.port;
      default = port;
      example = 11000;
      description = "Port number to run the OpenClaw gateway";
    };
    # automatically derived
    host = lib.mkOption {
      type = lib.types.str;
      default = "${srv.name}.${config.networking.hostName}";
      example = "openclaw-jon.cog";
      description = "Host running the OpenClaw gateway";
    };
    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to multi-line .env file with API_KEY=123";
    };
  };
  config = lib.mkIf srv.enable {
    persist.storage.directories = [srv.dataDir];

    # When the service is enabled, also enable the program and configure it for localhost
    programs.openclaw = {
      enable = lib.mkForce true;
      dataDir = lib.mkForce srv.dataDir;
      host = lib.mkForce "127.0.0.1";
      port = lib.mkForce srv.port;
    };

    age.secrets = lib.mkIf (srv.apiKeys != null) {
      openclaw-env.rekeyFile = srv.apiKeys;
    };

    # Setup systemd services to configure and run the OpenClaw gateway
    systemd.user.services = let
      EnvironmentFile =
        if srv.apiKeys != null
        then config.age.secrets.openclaw-env.path
        else false;

      Environment = [
        "PATH=${lib.concatStringsSep ":" path}"
        "OPENCLAW_HOME=${config.home.homeDirectory}"
        "OPENCLAW_STATE_DIR=${config.home.homeDirectory}/${srv.dataDir}"
        "OPENCLAW_CONFIG_PATH=${config.home.homeDirectory}/${srv.dataDir}/openclaw.json"
        "OPENCLAW_GATEWAY_PORT=${toString srv.port}"
        "OPENCLAW_SYSTEMD_UNIT=openclaw-gateway.service"
        "OPENCLAW_SERVICE_MARKER=openclaw"
        "OPENCLAW_SERVICE_KIND=gateway"
        "OPENCLAW_SERVICE_VERSION=npm"
      ];
    in {
      openclaw-gateway = {
        Unit = {
          Description = "OpenClaw Gateway (via home-manager)";
          After = ["network-online.target" "agenix.service"];
          Requires = ["agenix.service"];
          Wants = ["network-online.target"];
        };

        Service = {
          Type = "simple";
          inherit Environment EnvironmentFile;
          ExecStart = "${config.programs.openclaw.package}/bin/openclaw gateway";
          Restart = "always";
          RestartSec = 5;
          TimeoutStopSec = 30;
          TimeoutStartSec = 30;
          SuccessExitStatus = "0 143";
          KillMode = "control-group";

          # Hardening
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = false;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = false;
        };

        Install.WantedBy = ["default.target"];
      };
    };
  };
}
