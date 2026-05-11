{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) agentNames dataDir gatewayAgents;

  # Shared override for each agent's config.yaml
  overrides = let
    configFor = agentName: {
      # Customize memory to be bigger and use honcho
      memory = {
        provider = "honcho";
        memory_char_limit = 8000;
        user_char_limit = 5000;
        nudge_interval = 6;
        flush_min_turns = 3;
      };
      agent.gateway_notify_interval = 600;
      display.skin = agentName; # custom tui skin
    };
  in
    lib.mapAttrs (
      name: agent:
        (pkgs.formats.yaml {}).generate "hermes-agent-${name}-override.yaml" (
          lib.recursiveUpdate (lib.recursiveUpdate (configFor name) cfg.config) agent.config
        )
    )
    cfg.agents;

  # Generate agent skin (if it's missing)
  skins = let
    skinFor = agentName: let
      titleCase = v: lib.toUpper (builtins.substring 0 1 v) + builtins.substring 1 ((lib.stringLength v) - 1) v;
      agentTitle = titleCase agentName;
    in {
      name = agentName;
      description = "${agentTitle} branding";
      branding = {
        agent_name = agentTitle;
        welcome = "${agentTitle} here! Type your message or /help for commands.";
        goodbye = "See you later! 🤖";
        response_label = " 🤖 ${agentTitle} ";
        prompt_symbol = "🤖 ❯";
        help_header = "(🤖) Available Commands";
      };
    };
  in
    lib.genAttrs agentNames (
      name:
        (pkgs.formats.yaml {}).generate "hermes-agent-${name}-skin.yaml" (skinFor name)
    );
in {
  config = lib.mkIf cfg.enable {
    home.activation.hermes-agent-config = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${lib.concatMapStringsSep "\n" (agent: let
        override = overrides.${agent};
        skin = skins.${agent};
        python = "${pkgs.python3.withPackages (ps: [ps.pyyaml])}/bin/python";
      in
        # sh
        ''
          $DRY_RUN_CMD mkdir -p "${dataDir}/${agent}"
          $DRY_RUN_CMD mkdir -p "${dataDir}/${agent}/skins"
          $DRY_RUN_CMD rm -rf "${dataDir}/${agent}/profiles"
          $DRY_RUN_CMD mkdir -p "${dataDir}/${agent}/profiles"
          $DRY_RUN_CMD ${python} "${./config.py}" replace "${dataDir}/${agent}/config.yaml" "${override}"
          $DRY_RUN_CMD ${python} "${./config.py}" fill "${dataDir}/${agent}/skins/${agent}.yaml" "${skin}"
           ${lib.concatMapStringsSep "\n" (otherAgent:
             lib.optionalString (otherAgent != agent)
             # sh
             ''
               $DRY_RUN_CMD ln -sfn "../../${otherAgent}" "${dataDir}/${agent}/profiles/${otherAgent}"
             '')
           gatewayAgents}
        '')
      agentNames}
    '';
  };
}
