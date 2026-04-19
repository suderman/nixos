# services.hermes.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.services.hermes-agent;
  dir = "${config.home.homeDirectory}/${cfg.dataDir}";
  profileNames = builtins.attrNames cfg.profiles;
  profileHome = name:
    if name == "default"
    then dir
    else "${dir}/profiles/${name}";

  inherit (lib) concatMapStringsSep listToAttrs mod nameValuePair optionalString;
  inherit (lib.strings) charToInt stringToCharacters;

  deriveProfilePort = base: profile: salt: let
    maxOffset = 65535 - base - 1;
    offset =
      if maxOffset <= 0
      then throw "services.hermes-agent.apiPort must leave room for derived profile ports"
      else builtins.foldl' (
        acc: char: mod ((acc * 33) + charToInt char) maxOffset
      ) 5381 (stringToCharacters "${salt}:${profile}");
  in
    base + 1 + offset;

  apiPortFor = name:
    if name == "default"
    then cfg.apiPort
    else deriveProfilePort cfg.apiPort name "api";

  dashboardPortFor = name:
    if name == "default"
    then cfg.dashboardPort
    else deriveProfilePort cfg.dashboardPort name "dashboard";

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

  mkProfileEnv = keysEnv: name: let
    apiPort = apiPortFor name;
    dashboardPort = dashboardPortFor name;
  in ''
    mkdir -p "${profileHome name}"
    cat >"${profileHome name}/.env.base" <<'EOF'
API_SERVER_ENABLED=1
API_SERVER_PORT=${toString apiPort}
DASHBOARD_PORT=${toString dashboardPort}
EOF
    if [[ -f "${keysEnv}" ]]; then
      echo >>"${profileHome name}/.env.base"
      cat "${keysEnv}" >>"${profileHome name}/.env.base"
    fi
    chmod 600 "${profileHome name}/.env.base"
  '';

  mkGatewayService = name:
    nameValuePair
    (if name == "default" then "hermes-gateway" else "hermes-gateway-${name}")
    {
      Unit = {
        Description = "Hermes Agent Gateway${optionalString (name != "default") " (${name})"}";
        After = ["network-online.target" "agenix.service"];
        Requires = ["agenix.service"];
        Wants = ["network-online.target"];
      };

      Service = mkService {
        Type = "simple";
        Environment = [
          "PATH=${lib.concatStringsSep ":" path}"
          "HERMES_HOME=${profileHome name}"
        ];
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
        mkdir -p "${dir}" "${dir}/profiles"
        ${concatMapStringsSep "\n" (mkProfileEnv keysEnv) profileNames}
      '';

    systemd.user.services = listToAttrs (map mkGatewayService profileNames);
  };
}
