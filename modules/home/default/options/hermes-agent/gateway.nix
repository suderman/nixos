# services.hermes.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.services.hermes-agent;
  dir = "${config.home.homeDirectory}/${cfg.dataDir}";
  agentsDir = "${dir}/agents";
  agentNames = builtins.attrNames cfg.agents;
  agentHome = name: "${agentsDir}/${name}";

  inherit (lib) concatMapStringsSep listToAttrs mod nameValuePair;
  inherit (lib.strings) charToInt stringToCharacters;

  deriveAgentPort = base: agent: salt: let
    maxOffset = 65535 - base - 1;
    offset =
      if maxOffset <= 0
      then throw "services.hermes-agent.apiPort must leave room for derived agent ports"
      else
        builtins.foldl' (
          acc: char: mod ((acc * 33) + charToInt char) maxOffset
        )
        5381 (stringToCharacters "${salt}:${agent}");
  in
    base + 1 + offset;

  apiPortFor = name: deriveAgentPort cfg.apiPort name "api";

  dashboardPortFor = name: deriveAgentPort cfg.dashboardPort name "dashboard";

  path =
    config.home.sessionPath
    ++ [
      "${config.home.profileDirectory}/bin"
      "/run/current-system/sw/bin"
      "/usr/bin"
      "/bin"
    ];

  mkService = attr:
    attr
    // {
      Restart = "always";
      RestartSec = 5;
      TimeoutStopSec = 30;
      TimeoutStartSec = 30;
      SuccessExitStatus = "0 143";
      KillMode = "control-group";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = false;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = false;
    };

  mkAgentEnv = keysEnv: name: let
    apiPort = apiPortFor name;
    dashboardPort = dashboardPortFor name;
  in ''
        mkdir -p "${agentHome name}"
        cat >"${agentHome name}/.env.base" <<'EOF'
    API_SERVER_ENABLED=1
    API_SERVER_PORT=${toString apiPort}
    DASHBOARD_PORT=${toString dashboardPort}
    EOF
        if [[ -f "${keysEnv}" ]]; then
          echo >>"${agentHome name}/.env.base"
          cat "${keysEnv}" >>"${agentHome name}/.env.base"
        fi
        chmod 600 "${agentHome name}/.env.base"
  '';

  mkGatewayService = agent:
    nameValuePair
    "hermes-gateway-${agent}"
    {
      Unit = {
        Description = "Hermes Agent Gateway (${agent})";
        After = ["network-online.target" "agenix.service"];
        Requires = ["agenix.service"];
        Wants = ["network-online.target"];
      };

      Service = mkService {
        Type = "simple";
        Environment = [
          "PATH=${lib.concatStringsSep ":" path}"
          "HERMES_HOME=${agentHome agent}"
        ];
        # Aggressively clean up any stale gateway processes from prior
        # configurations or binary versions that may not honor --replace.
        ExecStartPre = "-/run/current-system/sw/bin/bash -c 'pkill -f \"hermes-gateway-${agent}\" 2>/dev/null; sleep 1'";
        ExecStart = "${cfg.package}/bin/hermes gateway run --replace";
      };

      Install.WantedBy = ["default.target"];
    };
in {
  config = lib.mkIf cfg.enable {
    home.activation.hermes-gateway = let
      keysEnv =
        if cfg.apiKeys != null
        then "${config.age.secrets.hermes-env.path}"
        else "/dev/null";
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        mkdir -p "${dir}" "${agentsDir}"
        ${concatMapStringsSep "\n" (mkAgentEnv keysEnv) agentNames}
      '';

    systemd.user.services = listToAttrs (map mkGatewayService agentNames);
  };
}
