{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) agentNames dataDir;

  # Honcho config generator
  honchoConfigFor = agentName: {
    baseUrl = "https://${osConfig.services.honcho.name}.${osConfig.networking.hostName}";
    hosts.hermes = {
      peerName = config.home.username;
      aiPeer = agentName;
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
    dialecticCadence = 3;
  };

  # Create custom honcho config per agent name
  agentHonchoFiles = lib.genAttrs agentNames (
    name: (pkgs.formats.json {}).generate "hermes-agent-${name}-honcho.json" (honchoConfigFor name)
  );
in {
  config = lib.mkIf cfg.enable {
    home.activation.hermes-agent-honcho = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${lib.concatMapStringsSep "\n" (agent: let
        honchoFile = agentHonchoFiles.${agent};
      in
        # sh
        ''
          $DRY_RUN_CMD mkdir -p "${dataDir}/${agent}"
          $DRY_RUN_CMD install -m644 "${honchoFile}" "${dataDir}/${agent}/honcho.json"
        '')
      agentNames}
    '';
  };
}
