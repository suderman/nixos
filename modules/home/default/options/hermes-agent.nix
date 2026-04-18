# services.hermes.enable = true;
{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.services.hermes-agent;
  cfgDir = ".hermes";
  hermesWrapper = pkgs.self.mkScript {
    name = "hermes";
    text = let
      pythonPath = with pkgs.python3.pkgs;
        makePythonPath [python-telegram-bot fastapi uvicorn];
      envKey = "/run/hermes/${toString config.home.uid}/key.env";
    in
      # bash
      ''
        export PYTHONPATH="${pythonPath}:''${PYTHONPATH:-}"
        export HERMES_HOME="''${HERMES_HOME:-${config.home.homeDirectory}/${cfgDir}}"
        mkdir -p "$HERMES_HOME"

        set -a
        [[ -f "${envKey}" ]] && . "${envKey}"
        [[ -f "$HERMES_HOME/.env.base" ]] && . "$HERMES_HOME/.env.base"
        [[ -f "$HERMES_HOME/.env" ]] && . "$HERMES_HOME/.env"
        set +a

        exec "${cfg.package}/bin/hermes" "$@"
      '';
  };
in {
  options.services.hermes-agent = {
    enable = lib.mkEnableOption "hermes-agent";

    name = lib.mkOption {
      type = lib.types.str;
      default = "hermes-${config.home.username}";
      example = "hermes-jon";
      description = "Instance name used for DNS and API";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.name}.${config.networking.hostName}";
      example = "hermes-jon.cog";
      description = "Host running the Hermes gateway";
    };

    package = lib.mkOption {
      type = lib.types.package;
      description = "The hermes-agent package to use";
      default = let
        basePackage = perSystem.llm-agents.hermes-agent;
        hermesWebDist = pkgs.buildNpmPackage {
          pname = "hermes-agent-web-dist";
          version = basePackage.version;
          src = basePackage.src;
          sourceRoot = "source/web";
          npmDepsHash = "sha256-Y0pOzdFG8BLjfvCLmsvqYpjxFjAQabXp1i7X9W/cCU4=";
          postPatch = ''
            substituteInPlace vite.config.ts \
              --replace-fail 'outDir: "../hermes_cli/web_dist"' 'outDir: "dist"'
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p "$out"
            cp -r dist "$out/web_dist"
            runHook postInstall
          '';
        };
      in
        basePackage.overrideAttrs (old: {
          postInstall =
            (old.postInstall or "")
            + ''
              hermes_cli_dir="$(echo "$out"/lib/python*/site-packages/hermes_cli)"
              rm -rf "$hermes_cli_dir/web_dist"
              cp -r ${hermesWebDist}/web_dist "$hermes_cli_dir/web_dist"
            '';
        });
    };

    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to encrypted .env file with API keys (OPENROUTER_API_KEY, etc.)";
    };

    apiPort = lib.mkOption {
      type = lib.types.port;
      default = 8642 + config.home.portOffset;
      description = "Port for the Hermes API server";
    };

    dashboardPort = lib.mkOption {
      type = lib.types.port;
      default = 9119 + config.home.portOffset;
      description = "Port for the Hermes web dashboard";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install hermes package
    home.packages = [cfg.package];

    # Add hermes wrapper to user path
    home.file.".local/bin/hermes".source = "${hermesWrapper}/bin/hermes";

    # Persist hermes home directory (stores config.yaml, .env, skills, sessions, etc.)
    persist.storage.directories = [cfgDir];

    # Register api keys with agenix
    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      hermes-env.rekeyFile = cfg.apiKeys;
    };

    # Create ~/.hermes/.env.base with declarative defaults and API keys.
    # ~/.hermes/.env remains mutable and overrides these values.
    home.activation.hermes = let
      dir = "${config.home.homeDirectory}/${cfgDir}";
      baseEnv =
        pkgs.writeText "hermes-base.env"
        # sh
        ''
          API_SERVER_ENABLED=1
          API_SERVER_PORT=${toString cfg.apiPort}
          DASHBOARD_PORT=${toString cfg.dashboardPort}
        '';
      keysEnv =
        if cfg.apiKeys != null
        then "${config.age.secrets.hermes-env.path}"
        else "/dev/null";
    in
      lib.hm.dag.entryAfter ["writeBoundary"]
      # bash
      ''
        mkdir -p ${dir}
        cat "${baseEnv}" >${dir}/.env.base
        if [[ -f "${keysEnv}" ]]; then
          echo >>${dir}/.env.base
          cat "${keysEnv}" >>${dir}/.env.base
        fi
        chmod 600 ${dir}/.env.base
      '';

    # Systemd user service for the Hermes gateway
    systemd.user.services = let
      path =
        config.home.sessionPath
        ++ [
          "${config.home.profileDirectory}/bin"
          "/run/current-system/sw/bin"
          "/usr/bin"
          "/bin"
        ];
      mkService = attr:
        attr
        // {
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
    in {
      hermes-gateway = {
        Unit = {
          Description = "Hermes Agent Gateway";
          After = ["network-online.target" "agenix.service"];
          Requires = ["agenix.service"];
          Wants = ["network-online.target"];
        };

        Service = mkService {
          Type = "simple";
          Environment = ["PATH=${lib.concatStringsSep ":" path}"];
          ExecStart = "${hermesWrapper}/bin/hermes gateway run";
        };

        Install.WantedBy = ["default.target"];
      };

      hermes-dashboard = {
        Unit = {
          Description = "Hermes Agent Dashboard";
          After = ["network-online.target" "agenix.service" "hermes-gateway.service"];
          Requires = ["agenix.service"];
          Wants = ["network-online.target" "hermes-gateway.service"];
        };

        Service = mkService {
          Type = "simple";
          Environment = [
            "PATH=${lib.concatStringsSep ":" path}"
            "GATEWAY_HEALTH_URL=http://127.0.0.1:${toString cfg.apiPort}/health/detailed"
          ];
          ExecStart = "${hermesWrapper}/bin/hermes dashboard --host 127.0.0.1 --port ${toString cfg.dashboardPort} --no-open";
        };

        Install.WantedBy = ["default.target"];
      };
    };
  };
}
