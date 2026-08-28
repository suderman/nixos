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
      default = perSystem.hermes-agent.default.override {
        extraDependencyGroups = ["messaging" "honcho" "anthropic"];
      };
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

            '';
          };

          homeAssistant = lib.mkEnableOption "Home Assistant credentials for this local profile";

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
          june.client = true;
          cid = {
            client = true;
            config.model.default = "gpt-5.4";
          };
        };
      };

    gateway = {
      enable = lib.mkEnableOption "one multiplex Hermes gateway for this host";

      port = lib.mkOption {
        type = lib.types.port;
        default = 8642 + config.home.portOffset;
        description = "Port for the host Hermes API server.";
      };
    };

    dashboard = {
      enable = lib.mkEnableOption "one machine-wide Hermes dashboard for this host";

      port = lib.mkOption {
        type = lib.types.port;
        default = 9119 + config.home.portOffset;
        description = "Port for the machine-wide Hermes dashboard.";
      };
    };

    packages = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      description = "The hermes-agent package of each agent.";
      default = {};
    };

    models = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Freeform attr set to store models for later use.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Persist the native Hermes root and named profiles.
    persist.storage.directories = [cfg.dataDir];

    # Decrypt secrets
    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      hermes-env.rekeyFile = cfg.apiKeys;
    };

    # Generate the root dotenv and a complete scoped dotenv for each local profile.
    systemd.user.services.hermes-agent-env = let
      inherit (config.lib.hermes-agent) dataDir localProfiles runDir;

      keysEnv =
        if cfg.apiKeys != null
        then config.age.secrets.hermes-env.path
        else "/dev/null";
    in {
      Unit = {
        Description = "Generate Hermes profile dotenv files";
        Requires = lib.optionals (cfg.apiKeys != null) ["agenix.service"];
        After = lib.optionals (cfg.apiKeys != null) ["agenix.service"];
        Before =
          lib.optionals cfg.gateway.enable ["hermes-gateway.service"]
          ++ lib.optionals cfg.dashboard.enable ["hermes-dashboard.service"];
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = perSystem.self.mkScript {
          text =
            # sh
            ''
              set -eu
              umask 077
              tmp=""
              profile_tmp=""
              cleanup() {
                [ -z "$tmp" ] || rm -f "$tmp"
                [ -z "$profile_tmp" ] || rm -f "$profile_tmp"
              }
              append_without_hass() {
                while IFS= read -r line || [ -n "$line" ]; do
                  case "$line" in
                    HASS_TOKEN=*|HASS_URL=*) continue ;;
                  esac
                  printf '%s\n' "$line"
                done <"$1"
              }
              trap cleanup EXIT

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

                  append_without_hass "${keysEnv}"
                ''}
              } >"$tmp"

              chmod 600 "$tmp"
              mv "$tmp" "${dataDir}/.env"
              tmp=""

              ${lib.concatMapStrings (profile: ''
                  profile_dir="${dataDir}/profiles/${profile}"
                  mkdir -p "$profile_dir"
                  profile_tmp="$(mktemp "$profile_dir/.env.tmp.XXXXXX")"
                  cat "${dataDir}/.env" >"$profile_tmp"

                  ${lib.optionalString (cfg.apiKeys != null) (
                    if cfg.agents.${profile}.homeAssistant
                    then ''cat "${keysEnv}" >>"$profile_tmp"''
                    else ''append_without_hass "${keysEnv}" >>"$profile_tmp"''
                  )}

                  for source in "$profile_dir/.env.local" "$profile_dir/.env.camofox"; do
                    if [ -r "$source" ]; then
                      printf '\n' >>"$profile_tmp"
                      ${
                    if cfg.agents.${profile}.homeAssistant
                    then ''cat "$source" >>"$profile_tmp"''
                    else ''append_without_hass "$source" >>"$profile_tmp"''
                  }
                    fi
                  done

                  chmod 600 "$profile_tmp"
                  mv "$profile_tmp" "$profile_dir/.env"
                  profile_tmp=""
                '')
                localProfiles}
            '';
        };
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
