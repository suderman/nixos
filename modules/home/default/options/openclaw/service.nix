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
    apiKeys = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      description = "Path to multi-line .env file with API_KEY=123";
    };
  };
  config = lib.mkIf cfg.enable {
    persist.storage.directories = [cfg.dataDir];

    # When the service is enabled, also enable the program and configure it for localhost
    programs.openclaw = {
      enable = lib.mkForce true;
      package = lib.mkForce cfg.package;
      dataDir = lib.mkForce cfg.dataDir;
      host = lib.mkForce "127.0.0.1";
      port = lib.mkForce cfg.port;
    };

    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      openclaw-env.rekeyFile = cfg.apiKeys;
    };

    # Setup systemd services to configure and run the OpenClaw gateway
    systemd.user.services = let
      Environment = let
        paths = builtins.concatStringsSep ":" [
          "${config.xdg.dataHome}/gem/bin"
          "${config.xdg.dataHome}/pipx/bin"
          "${config.xdg.dataHome}/composer/vendor/bin"
          "${config.xdg.dataHome}/luarocks/bin"
          "${config.xdg.dataHome}/npm/bin"
          "${config.xdg.dataHome}/pnpm"
          "${config.xdg.dataHome}/bun/bin"
          "${config.home.homeDirectory}/.local/bin"
          "${config.home.homeDirectory}/.nix-profile/bin"
          "/etc/profiles/per-user/bot/bin"
          "/run/current-system/sw/bin"
        ];
      in [
        "OPENCLAW_HOME=${config.home.homeDirectory}"
        "OPENCLAW_STATE_DIR=${config.home.homeDirectory}/${cfg.dataDir}"
        "OPENCLAW_CONFIG_PATH=${config.home.homeDirectory}/${cfg.dataDir}/openclaw.json"
        "PATH=${paths}:$PATH"
      ];
    in {
      oc-setup = {
        Unit.Description = "OpenClaw Gateway Setup";
        Service = {
          Type = "oneshot";
          inherit Environment;

          ExecStart = perSystem.self.mkScript {
            text =
              # bash
              ''
                # Generate gateway override for openclaw.json
                cat >${runDir}/openclaw-gateway.json <<EOF
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
                chmod 600 ${runDir}/openclaw-gateway.json
              ''
              +
              # bash
              ''
                # Ensure ~/.openclaw is setup
                install -dm700 $OPENCLAW_STATE_DIR
                openclaw setup

                # Merge the override into OpenClaw's config json
                if [[ -f $OPENCLAW_CONFIG_PATH ]]; then

                  # Base json (comments removed)
                  json_repair $OPENCLAW_CONFIG_PATH >${runDir}/openclaw-base.json
                  chmod 600 ${runDir}/openclaw-base.json

                  # Merged json (mixing gateway into base)
                  {
                    echo "/* OpenClaw Gateway URLs:"
                    echo "http://localhost:${toString cfg.port}?token=$(tr -d '\n' <${runDir}/gateway)"
                    echo "https://${cfg.host}?token=$(tr -d '\n' <${runDir}/gateway)"
                    echo "*/"
                    jq '.gateway = input.gateway' ${runDir}/openclaw-base.json ${runDir}/openclaw-gateway.json
                  } >${runDir}/openclaw.json
                  chmod 600 ${runDir}/openclaw.json

                  # Replace original config with merged
                  mv ${runDir}/openclaw.json "$OPENCLAW_CONFIG_PATH"
                fi
              '';
            path = [cfg.package pkgs.jq pkgs.json-repair];
          };

          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = ["default.target"];
      };

      openclaw-gateway = {
        Unit = {
          Description = "OpenClaw Gateway";
          After = ["network-online.target" "oc-setup.service" "agenix.service"];
          Requires = ["oc-setup.service" "agenix.service"];
          Wants = ["network-online.target"];
        };

        Service = {
          Type = "simple";
          inherit Environment;
          EnvironmentFile =
            if cfg.apiKeys != null
            then config.age.secrets.openclaw-env.path
            else false;
          ExecStart = "${cfg.package}/bin/openclaw gateway";
          Restart = "on-failure";
          RestartSec = 5;

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
