# config.services.openclaw.enable = true;
{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.services.openclaw;
  inherit (config.lib.openclaw) port runDir;
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
      default = "${cfg.name}.${config.networking.hostName}";
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

    # Setup systemd services to configure and run the OpenClaw gateway
    systemd.user.services = let
      Environment = [
        "OPENCLAW_HOME=${config.home.homeDirectory}"
        "OPENCLAW_STATE_DIR=${config.home.homeDirectory}/${cfg.dataDir}"
        "OPENCLAW_CONFIG_PATH=${config.home.homeDirectory}/${cfg.dataDir}/openclaw.json"
      ];
    in {
      openclaw-setup = {
        Unit = {
          Description = "OpenClaw Gateway Setup";
          After = ["network-online.target"];
          Wants = ["network-online.target"];
        };
        Service = {
          inherit Environment;
          Type = "oneshot";

          ExecStart = perSystem.self.mkScript {
            text =
              # bash
              ''
                # Generate gateway override for openclaw.json
                cat >${runDir}/gateway.json <<EOF
                {
                  "gateway": {
                    "port": ${toString cfg.port},
                    "mode": "local",
                    "bind": "loopback",
                    "auth": { "mode": "token", "token": "$(tr -d '\n' <${runDir}/gateway)" },
                    "trustedProxies": ["127.0.0.1", "${config.networking.address}"],
                    "controlUi": { "allowedOrigins": ["https://${cfg.host}"] }
                  }
                }
                EOF
              ''
              +
              # bash
              ''
                # Ensure ~/.openclaw is setup
                install -dm700 $OPENCLAW_STATE_DIR
                openclaw setup

                # Merge the override into OpenClaw's config json
                if [[ -f $OPENCLAW_CONFIG_PATH ]]; then
                  tmp="$(mktemp)"
                  {
                    echo "/* OpenClaw Gateway URLs:"
                    echo "http://localhost:${toString cfg.port}?token=$(tr -d '\n' <${runDir}/gateway)"
                    echo "https://${cfg.host}?token=$(tr -d '\n' <${runDir}/gateway)"
                    echo "*/"
                    jq '.gateway = input.gateway' "$OPENCLAW_CONFIG_PATH" "${runDir}/gateway.json"
                  } >"$tmp"
                  mv "$tmp" "$OPENCLAW_CONFIG_PATH"
                fi
              '';
            path = [cfg.package pkgs.jq];
          };

          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = ["default.target"];
      };

      openclaw-gateway = {
        Unit = {
          Description = "OpenClaw Gateway";
          After = ["network-online.target" "openclaw-setup"];
          Wants = ["network-online.target" "openclaw-setup"];
        };

        Service = {
          inherit Environment;
          Type = "simple";
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
    };
  };
}
