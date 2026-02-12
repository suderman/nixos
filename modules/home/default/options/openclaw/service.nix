# config.services.openclaw.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.services.openclaw;
  runDir = "/run/user/${toString config.home.uid}/openclaw";
in {
  options.services.openclaw = {
    enable = lib.mkEnableOption "openclaw";
    package = lib.mkOption {
      type = lib.types.package;
      default = perSystem.llm-agents.openclaw;
    };
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
    # automatically generated
    port = lib.mkOption {
      type = lib.types.port;
      default = 11000 + config.home.portOffset;
      example = 11000;
      description = "Port number to run the OpenClaw gateway";
    };
    # automatically generated
    host = lib.mkOption {
      type = lib.types.str;
      # default = "${cfg.name}.${config.networking.hostName}";
      default = "${cfg.name}.cog"; # FIXME
      example = "openclaw-jon.cog";
      description = "Host running the OpenClaw gateway";
    };
  };
  config = lib.mkIf cfg.enable {
    persist.storage.directories = [cfg.dataDir];

    # When the service is enabled, also enable the program and configure it for localhost
    programs.openclaw = {
      enable = true;
      package = cfg.package;
      host = lib.mkForce "127.0.0.1";
      port = lib.mkForce cfg.port;
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
              cat >${runDir}/gateway.env <<EOF
              OPENCLAW_STATE_DIR=${config.home.homeDirectory}/${cfg.dataDir}
              OPENCLAW_GATEWAY_PORT=${toString cfg.port}
              OPENCLAW_GATEWAY_BIND=127.0.0.1
              OPENCLAW_GATEWAY_TRUSTEDPROXIES=127.0.0.1,${config.networking.address}
              OPENCLAW_GATEWAY_CONTROLUI_ALLOWEDORIGINS=https://${cfg.host}
              OPENCLAW_GATEWAY_TOKEN=$(cat ${runDir}/gateway)
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
        EnvironmentFile = "${runDir}/gateway.env";
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
