{
  osConfig,
  config,
  lib,
  perSystem,
  flake,
  ...
}: let
  cfg = config.services.hermes-agent;
in {
  imports = flake.lib.ls ./.;

  options.services.hermes-agent = {
    enable = lib.mkEnableOption "hermes-agent";

    name = lib.mkOption {
      type = lib.types.str;
      default = "hermes-${config.home.username}";
      example = "hermes-jon";
      description = "Instance name used for DNS and API";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = ".local/share/hermes";
      description = "Directory containing all managed Hermes agent homes.";
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      description = "The hermes-agent base package to use";
      default = perSystem.hermes-agent.default;
    };

    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to encrypted .env file with API keys (OPENROUTER_API_KEY, etc.)";
    };

    agents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of agent names";
      default = ["hermes"];
      example = ["june" "cid" "pax"];
    };

    packages = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      description = "The hermes-agent package of each agent";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    # Persist all standalone Hermes homes.
    persist.storage.directories = [cfg.dataDir];

    # Decrypt secrets
    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      hermes-env.rekeyFile = cfg.apiKeys;
    };

    # Generate shared dotenv file for all hermes agents
    systemd.user.services.hermes-agent-env = let
      inherit (config.lib.hermes-agent) dataDir runDir;

      keysEnv =
        if cfg.apiKeys != null
        then config.age.secrets.hermes-env.path
        else "/dev/null";
    in {
      Unit = {
        Description = "Generate shared Hermes agent dotenv";
        Requires = lib.optionals (cfg.apiKeys != null) ["agenix.service"];
        After = lib.optionals (cfg.apiKeys != null) ["agenix.service"];
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = perSystem.self.mkScript {
          text = let
            honchoConfigFor = agent:
              builtins.toJSON {
                hosts.hermes = {
                  peerName = config.home.username;
                  aiPeer = agent;
                  workspace = osConfig.networking.hostName;
                  observationMode = "directional";
                  writeFrequency = "async";
                  recallMode = "hybrid";
                  contextTokens = 2000;
                  dialecticCadence = 3;
                  dialecticReasoningLevel = "medium";
                  sessionStrategy = "per-session";
                  enabled = true;
                  saveMessages = true;
                };
                baseUrl = "https://${osConfig.services.honcho.name}.${osConfig.networking.hostName}";
                dialecticCadence = 3;
              };
          in
            # sh
            ''
              mkdir -p "${dataDir}"
              if [ ! -r "${runDir}/key" ]; then
                echo "Missing Hermes API server key: ${runDir}/key" >&2
                exit 1
              fi

              tmp="$(mktemp "${dataDir}/.env.tmp.XXXXXX")"
              {
                echo "HERMES_TUI=1"
                echo "API_SERVER_ENABLED=1"
                printf 'API_SERVER_KEY=%s\n' "$(cat "${runDir}/key")"

                ${lib.optionalString (cfg.apiKeys != null)
                # sh
                ''
                  if [ ! -r "${keysEnv}" ]; then
                    echo "Missing Hermes agenix env file: ${keysEnv}" >&2
                    exit 1
                  fi

                  cat "${keysEnv}"
                ''}
              } >"$tmp"

              chmod 600 "$tmp"
              mv "$tmp" "${dataDir}/.env"

              ${lib.concatMapStringsSep "\n" (agent:
                # sh
                ''
                  mkdir -p "${dataDir}/${agent}"
                  printf '%s\n' '${honchoConfigFor agent}' > "${dataDir}/${agent}/honcho.json"
                '')
              cfg.agents}
            '';
        };
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
