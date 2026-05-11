{
  lib,
  config,
  ...
}: let
  cfg = config.services.hermes-agent;
in {
  config.lib.hermes-agent = lib.mkIf cfg.enable rec {
    # Parent data diretory for all hermes agents
    dataDir = "${config.home.homeDirectory}/${cfg.dataDir}";

    # Agent names declared in the module.
    agentNames = builtins.attrNames cfg.agents;

    # Agents with gateway enabled.
    gatewayAgents = builtins.attrNames (lib.filterAttrs (_: agent: agent.gateway) cfg.agents);

    # Agents with local client wrappers on this host.
    localClientAgents = builtins.attrNames (
      lib.filterAttrs (_: agent: agent.gateway || agent.client == true) cfg.agents
    );

    # Agents with SSH client shims on this host.
    remoteClientAgents = builtins.attrNames (
      lib.filterAttrs (_: agent: builtins.isString agent.client) cfg.agents
    );

    # Agents runnable from this host, local or remote.
    clientAgents = localClientAgents ++ remoteClientAgents;

    # The api secret is written to the user's run directory
    runDir = "/run/hermes/${toString config.home.uid}";

    # Seed is used to derive api secret
    seed = "hermes:${config.home.username}:${config.networking.hostName}";

    # Deterministically derive a stable port above `base` from `name`, using `base`
    # both as the lower bound and as part of the hash namespace to reduce collisions.
    derivePort = name: base: let
      op = acc: char: lib.mod ((acc * 33) + lib.strings.charToInt char) base;
      chars = lib.strings.stringToCharacters "${toString base}:${name}";
    in
      base + 1 + (builtins.foldl' op 5381 chars);

    # Port for the Hermes API server (default 8642)
    apiPortFor = agent: derivePort agent (8642 + config.home.portOffset);

    # Port for the Hermes web dashbaord (default 9119)
    dashboardPortFor = agent: derivePort agent (9119 + config.home.portOffset);
  };
}
