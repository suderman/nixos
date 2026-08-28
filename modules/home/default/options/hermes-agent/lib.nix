{
  lib,
  config,
  ...
}: let
  cfg = config.services.hermes-agent;
in {
  config.lib.hermes-agent = lib.mkIf cfg.enable rec {
    # Native Hermes root containing the default profile and profiles/<name>.
    dataDir = "${config.home.homeDirectory}/${cfg.dataDir}";

    # Agent names declared in the module.
    agentNames = builtins.attrNames cfg.agents;

    # Named profiles whose state lives on this host.
    localProfiles = builtins.attrNames (
      lib.filterAttrs (_: agent: agent.client == true) cfg.agents
    );

    # Agents with SSH client shims on this host.
    remoteClientAgents = builtins.attrNames (
      lib.filterAttrs (_: agent: builtins.isString agent.client) cfg.agents
    );

    # Agents runnable from this host, local or remote.
    clientAgents = localProfiles ++ remoteClientAgents;

    profileDirFor = name: "${dataDir}/profiles/${name}";

    # The api secret is written to the user's run directory
    runDir = "/run/hermes/${toString config.home.uid}";

    # Seed is used to derive api secret
    seed = "hermes:${config.home.username}:${config.networking.hostName}";

    apiPort = cfg.gateway.port;
    dashboardPort = cfg.dashboard.port;
  };
}
