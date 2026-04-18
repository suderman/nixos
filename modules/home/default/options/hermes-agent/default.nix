{
  lib,
  config,
  pkgs,
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
      default = ".hermes";
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

    proxy = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {
        default = "hermes.kit";
        grep = "grep.kit";
      };
      description = ''
        Profile-to-hostname map for Traefik exposure.
        The reserved key `default` targets the root Hermes home, and every other
        key targets a mutable profile under `profiles/<name>`.
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

    gatewaySyncPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      description = "The hermes-agent gateway sync script to use";
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    # Add base, sync, and wrapped packages to path
    home.packages = [cfg.basePackage cfg.gatewaySyncPackage];
    home.file.".local/bin/hermes".source = "${cfg.package}/bin/hermes";

    # Persist ~/.hermes
    persist.storage.directories = [cfg.dataDir];

    # Decrypt secrets
    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      hermes-env.rekeyFile = cfg.apiKeys;
    };
  };
}
