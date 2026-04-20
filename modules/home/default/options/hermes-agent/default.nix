{
  lib,
  config,
  perSystem,
  flake,
  ...
}: let
  cfg = config.services.hermes-agent;
  agentType = lib.types.submodule ({name, ...}: {
    options.proxy = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example =
        if name == "june"
        then "june.kit"
        else "agent.kit";
      description = ''
        Optional Traefik hostname for this Hermes agent. Each declared agent gets
        its own standalone Hermes home under `${cfg.dataDir}/<name>`.
      '';
    };
  });
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

    host = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.name}.${config.networking.hostName}";
      example = "hermes-jon.cog";
      description = "Host running the Hermes gateway";
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
      description = "Port reserved for the Hermes web dashboard";
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf agentType;
      default = {};
      example = {
        june.proxy = "june.kit";
        cid.proxy = "cid.kit";
        pax.proxy = "pax.kit";
      };
      description = ''
        Declarative standalone Hermes agents. Each agent is an equal peer with
        its own isolated Hermes home under `${cfg.dataDir}/<name>`. The
        module creates the directory structure and `.env.base` for each agent on
        a best-effort basis, while leaving the rest of the mutable Hermes home to
        Hermes itself.
      '';
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      description = "The hermes-agent wrapper script to use";
      default = null;
    };

    basePackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      description = "The hermes-agent base package to use";
      default = perSystem.llm-agents.hermes-agent;
    };
  };

  config = lib.mkIf cfg.enable {
    # Add base and wrapped packages to path
    home.packages = [cfg.basePackage];
    home.file.".local/bin/hermes".source = "${cfg.package}/bin/hermes";

    # Persist all standalone Hermes homes.
    persist.storage.directories = [cfg.dataDir];

    # Decrypt secrets
    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      hermes-env.rekeyFile = cfg.apiKeys;
    };
  };
}
