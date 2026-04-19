{
  lib,
  config,
  perSystem,
  flake,
  ...
}: let
  cfg = config.services.hermes-agent;
  profileType = lib.types.submodule ({name, ...}: {
    options.proxy = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = if name == "default" then "hermes.kit" else "grep.kit";
      description = ''
        Optional Traefik hostname for this Hermes profile. The reserved profile
        name `default` targets the root Hermes home, and every other name maps
        to `${cfg.dataDir}/profiles/<name>`.
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

    profiles = lib.mkOption {
      type = lib.types.attrsOf profileType;
      default = {
        default = {};
      };
      example = {
        default.proxy = "hermes.kit";
        grep.proxy = "grep.kit";
      };
      description = ''
        Declarative Hermes profiles. The reserved profile name `default` maps to
        the root Hermes home, and named profiles map to `${cfg.dataDir}/profiles`.
        Hermes directories and `.env.base` files are created on a best-effort
        basis for each declared profile.
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

    # Persist ~/.hermes
    persist.storage.directories = [cfg.dataDir];

    # Decrypt secrets
    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      hermes-env.rekeyFile = cfg.apiKeys;
    };
  };
}
