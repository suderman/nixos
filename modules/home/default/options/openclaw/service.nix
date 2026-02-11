# config.services.openclaw.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.services.openclaw;
in {
  options.services.openclaw = {
    enable = lib.mkEnableOption "openclaw";
    package = lib.mkOption {
      type = lib.types.package;
      default = perSystem.llm-agents.openclaw;
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = config.home.username;
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 11000 + config.home.portOffset;
      example = 11000;
      description = "Port number to run the OpenClaw gateway";
    };
    host = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.name}.${config.networking.hostName}";
      description = "Host running the OpenClaw gateway";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = ".openclaw";
    };
  };
  config = lib.mkIf cfg.enable {
    persist.storage.directories = [cfg.dataDir];

    programs.openclaw = {
      enable = true;
      package = cfg.package;
      host = lib.mkForce "${cfg.host}";
      port = lib.mkForce 443;
    };

    systemd.user.services.openclaw-env = {
      Unit = {
        Description = "OpenClaw Prepare Gateway Environment";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };
      Service = {
        Type = "oneshot";

        ExecStart = perSystem.self.mkScript {
          text =
            # bash
            ''
              cat >/run/openclaw/gateway.env <<EOF
              OPENCLAW_GATEWAY_TOKEN=$(cat /run/openclaw/gateway)
              EOF
            '';
        };

        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["default.target"];
    };

    systemd.user.services.openclaw-gateway = {
      Unit = {
        Description = "OpenClaw Gateway";
        After = ["network-online.target" "openclaw-env"];
        Wants = ["network-online.target" "openclaw-env"];
      };

      Service = {
        Type = "simple";

        EnvironmentFile = "/run/openclaw/gateway.env";
        Environment = [
          "OPENCLAW_STATE_DIR=${config.home.homeDirectory}/${cfg.dataDir}"
          "OPENCLAW_GATEWAY_PORT=${toString cfg.port}"
          "OPENCLAW_GATEWAY_BIND=lan"
          "OPENCLAW_GATEWAY_TRUSTEDPROXIES=127.0.0.1,${config.networking.address}"
          "OPENCLAW_GATEWAY_CONTROLUI_ALLOWEDORIGINS=https://${cfg.host}"
        ];

        ExecStart = "${cfg.package}/bin/openclaw gateway";

        Restart = "on-failure";
        RestartSec = 2;

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

    programs.javascript.enable = true;
    programs.python.enable = true;
  };
}
