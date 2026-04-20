{
  lib,
  config,
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
      default = perSystem.llm-agents.hermes-agent;
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
    home.activation.hermes-agent = let
      inherit (config.lib.hermes-agent) dataDir runDir;
      keysEnv =
        if cfg.apiKeys != null
        then "${config.age.secrets.hermes-env.path}"
        else "/dev/null";
      agentNames = lib.concatStringsSep "," cfg.agents;
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Create parent directory dotenv with keys
        mkdir -p "${dataDir}"
        echo "API_SERVER_ENABLED=1" >${dataDir}/.env
        echo "API_SERVER_KEY=$(cat ${runDir}/key)" >>${dataDir}/.env
        [[ -f "${keysEnv}" ]] && cat "${keysEnv}" >>${dataDir}/.env
        chmod 600 ${dataDir}/.env

        # Ensure each agent directory exists
        mkdir -p ${dataDir}/{${agentNames}}
      '';
  };
}
