# services.hermes.enable = true;
{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.services.hermes;
  cfgDir = ".hermes";
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
  defaultPackage = basePackage.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        hermes_cli_dir="$(echo "$out"/lib/python*/site-packages/hermes_cli)"
        rm -rf "$hermes_cli_dir/web_dist"
        cp -r ${hermesWebDist}/web_dist "$hermes_cli_dir/web_dist"
      '';
  });
  hermesPythonPath = pkgs.python3.pkgs.makePythonPath [
    pkgs.python3.pkgs.python-telegram-bot
    pkgs.python3.pkgs.fastapi
    pkgs.python3.pkgs.uvicorn
  ];
  hermes = pkgs.self.mkScript {
    name = "hermes";
    text =
      # bash
      ''
        HERMES_HOME="''${HERMES_HOME:-${config.home.homeDirectory}/${cfgDir}}"
        HERMES_BIN="${cfg.package}/bin/hermes"
        HERMES_ENV_BASE="$HERMES_HOME/.env.base"
        HERMES_ENV_KEY="/run/hermes/${toString config.home.uid}/key.env"
        HERMES_ENV="$HERMES_HOME/.env"

        mkdir -p "$HERMES_HOME"

        set -a
        [[ -f "$HERMES_ENV_BASE" ]] && . "$HERMES_ENV_BASE"
        [[ -f "$HERMES_ENV_KEY" ]] && . "$HERMES_ENV_KEY"
        [[ -f "$HERMES_ENV" ]] && . "$HERMES_ENV"
        set +a

        export HERMES_HOME
        export PYTHONPATH="${hermesPythonPath}:''${PYTHONPATH:-}"
        exec "$HERMES_BIN" "$@"
      '';
  };
in {
  options.services.hermes = {
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
      default = defaultPackage;
      description = "The hermes-agent package to use";
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
    home.file.".local/bin/hermes".source = "${hermes}/bin/hermes";

    # Persist hermes home directory (stores config.yaml, .env, skills, sessions, etc.)
    persist.storage.directories = [cfgDir];

    # Register api keys with agenix
    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      hermes-env.rekeyFile = cfg.apiKeys;
    };

    # Create ~/.hermes/.env.base with declarative defaults and API keys.
    # ~/.hermes/.env remains mutable and overrides these values.
    home.activation.hermes = let
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
        mkdir -p "${config.home.homeDirectory}/${cfgDir}"
        DOTENV_BASE="${config.home.homeDirectory}/${cfgDir}/.env.base"
        DOTENV_MUTABLE="${config.home.homeDirectory}/${cfgDir}/.env"

        # One-time migration from the old module behavior that wrote
        # declarative values directly into ~/.hermes/.env.
        if [[ -f "$DOTENV_MUTABLE" && ! -f "$DOTENV_BASE" ]]; then
          cp "$DOTENV_MUTABLE" "$DOTENV_MUTABLE.pre-nix-base-migration"
          grep -vE '^(API_SERVER_ENABLED|API_SERVER_PORT|DASHBOARD_PORT)=' "$DOTENV_MUTABLE.pre-nix-base-migration" > "$DOTENV_MUTABLE"
          chmod 600 "$DOTENV_MUTABLE"
        fi

        cat "${baseEnv}" > "$DOTENV_BASE"
        if [[ -f "${keysEnv}" ]]; then
          echo >> "$DOTENV_BASE"
          cat "${keysEnv}" >> "$DOTENV_BASE"
        fi

        chmod 600 "$DOTENV_BASE"
      '';

    # Systemd user service for the Hermes gateway
    systemd.user.services.hermes-gateway = {
      Unit = {
        Description = "Hermes Agent Gateway";
        After = ["network-online.target" "agenix.service"];
        Requires = ["agenix.service"];
        Wants = ["network-online.target"];
      };

      Service = {
        Type = "simple";
        Environment = let
          path =
            config.home.sessionPath
            ++ [
              "${config.home.profileDirectory}/bin"
              "/run/current-system/sw/bin"
              "/usr/bin"
              "/bin"
            ];
        in [
          "PATH=${lib.concatStringsSep ":" path}"
          "HERMES_HOME=${config.home.homeDirectory}/${cfgDir}"
        ];
        ExecStart = "${hermes}/bin/hermes gateway run";
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

    systemd.user.services.hermes-dashboard = {
      Unit = {
        Description = "Hermes Agent Dashboard";
        After = ["network-online.target" "agenix.service" "hermes-gateway.service"];
        Requires = ["agenix.service"];
        Wants = ["network-online.target" "hermes-gateway.service"];
      };

      Service = {
        Type = "simple";
        Environment = let
          path =
            config.home.sessionPath
            ++ [
              "${config.home.profileDirectory}/bin"
              "/run/current-system/sw/bin"
              "/usr/bin"
              "/bin"
            ];
        in [
          "PATH=${lib.concatStringsSep ":" path}"
          "HERMES_HOME=${config.home.homeDirectory}/${cfgDir}"
          "GATEWAY_HEALTH_URL=http://127.0.0.1:${toString cfg.apiPort}/health/detailed"
        ];
        ExecStart = "${hermes}/bin/hermes dashboard --host 127.0.0.1 --port ${toString cfg.dashboardPort} --no-open";
        Restart = "always";
        RestartSec = 5;
        TimeoutStopSec = 30;
        TimeoutStartSec = 30;
        SuccessExitStatus = "0 143";
        KillMode = "control-group";

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
}
