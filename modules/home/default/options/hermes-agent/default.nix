{
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
      default = perSystem.hermes-agent.default;
      description = "The hermes-agent base package to use";
    };

    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to encrypted .env file with API keys (OPENROUTER_API_KEY, etc.)";
    };

    config = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Shared Hermes configuration applied to all agents later.";
    };

    agents = let
      agentType = lib.types.submodule ({name, ...}: {
        options = {
          client = lib.mkOption {
            type = lib.types.either lib.types.bool lib.types.str;
            default = false;
            example = true;
            description = ''
              How this host should expose the ${name} client.

              - `true`: install a local wrapper for this agent
              - `"host"`: install an SSH shim that runs `${name}` on `host.home`
              - `false`: do not install a client wrapper on this host

              Agents with `gateway = true` implicitly get a local client.
            '';
          };

          gateway = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to run and expose the Hermes gateway for this agent.";
          };

          config = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = {};
            description = "Agent-specific Hermes configuration to merge with shared config later.";
          };
        };
      });
    in
      lib.mkOption {
        type = lib.types.attrsOf agentType;
        description = "Hermes agents keyed by agent name.";
        default = {};
        example = {
          june.gateway = true;
          cid = {
            gateway = true;
            config.model.default = "gpt-5.4";
          };
        };
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
          text =
            # sh
            ''
              mkdir -p "${dataDir}"
              if [ ! -r "${runDir}/key" ]; then
                echo "Missing Hermes API server key: ${runDir}/key" >&2
                exit 1
              fi

              tmp="$(mktemp "${dataDir}/.env.tmp.XXXXXX")"
              {
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
            '';
        };
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
