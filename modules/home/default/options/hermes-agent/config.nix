{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) dataDir localProfiles profileDirFor;
  yaml = pkgs.formats.yaml {};
  python = "${pkgs.python3.withPackages (ps: [ps.pyyaml])}/bin/python";

  commonProfileConfig = agentName: {
    memory = {
      provider = "honcho";
      memory_char_limit = 8000;
      user_char_limit = 5000;
      nudge_interval = 6;
      flush_min_turns = 3;
    };
    compression.threshold = 0.4;
    cron.wrap_response = false;
    agent.gateway_notify_interval = 600;
    display.skin = agentName;
    browser.camofox.managed_persistence = true;
    platforms.api_server.enabled = false;
  };

  rootOverride = yaml.generate "hermes-root-override.yaml" (
    lib.recursiveUpdate cfg.config {
      gateway = {
        multiplex_profiles = cfg.gateway.enable;
        multiplex_profile_allowlist = localProfiles;
      };
    }
  );

  profileOverrides = lib.genAttrs localProfiles (
    name:
      yaml.generate "hermes-agent-${name}-override.yaml" (
        lib.recursiveUpdate
        (lib.recursiveUpdate (commonProfileConfig name) cfg.config)
        cfg.agents.${name}.config
      )
  );

  titleCase = value:
    lib.toUpper (builtins.substring 0 1 value)
    + builtins.substring 1 ((lib.stringLength value) - 1) value;

  profileMetadata = lib.genAttrs localProfiles (
    name:
      yaml.generate "hermes-agent-${name}-profile.yaml" {
        display_name = titleCase name;
      }
  );

  rootMetadata = yaml.generate "hermes-root-profile.yaml" {
    display_name = "Fleet";
    description = "Nix-managed administrative profile";
  };

  skins = lib.genAttrs localProfiles (
    name: let
      agentTitle = titleCase name;
    in
      yaml.generate "hermes-agent-${name}-skin.yaml" {
        inherit name;
        description = "${agentTitle} branding";
        branding = {
          agent_name = agentTitle;
          welcome = "${agentTitle} here! Type your message or /help for commands.";
          goodbye = "See you later! 🤖";
          response_label = " 🤖 ${agentTitle} ";
          prompt_symbol = "🤖 ❯";
          help_header = "(🤖) Available Commands";
        };
      }
  );
in {
  config = lib.mkIf cfg.enable {
    home.activation.hermes-agent-config = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "${dataDir}/profiles"
      # Managed Hermes verifies this directory skeleton instead of creating it.
      $DRY_RUN_CMD install -dm700 \
        "${dataDir}/cron" \
        "${dataDir}/sessions" \
        "${dataDir}/logs" \
        "${dataDir}/memories"
      $DRY_RUN_CMD ${python} "${./config.py}" replace "${dataDir}/config.yaml" "${rootOverride}"
      $DRY_RUN_CMD ${python} "${./config.py}" fill "${dataDir}/profile.yaml" "${rootMetadata}"

      ${lib.concatMapStringsSep "\n" (profile: let
          profileDir = profileDirFor profile;
        in ''
          $DRY_RUN_CMD install -dm700 \
            "${profileDir}" \
            "${profileDir}/cron" \
            "${profileDir}/sessions" \
            "${profileDir}/logs" \
            "${profileDir}/memories" \
            "${profileDir}/skins"
          $DRY_RUN_CMD ${python} "${./config.py}" replace "${profileDir}/config.yaml" "${profileOverrides.${profile}}"
          $DRY_RUN_CMD ${python} "${./config.py}" fill "${profileDir}/profile.yaml" "${profileMetadata.${profile}}"
          $DRY_RUN_CMD ${python} "${./config.py}" fill "${profileDir}/skins/${profile}.yaml" "${skins.${profile}}"
        '')
        localProfiles}
    '';
  };
}
