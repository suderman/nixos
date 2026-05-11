{
  config,
  lib,
  ...
}: let
  cfg = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) dataDir dashboardPortFor gatewayAgents;
in {
  config = lib.mkIf cfg.enable {
    systemd.user.services = lib.listToAttrs (map (
        agent: let
          hermes = "${cfg.packages.${agent}}/bin/${agent}";
          path =
            config.home.sessionPath
            ++ [
              "${config.home.profileDirectory}/bin"
              "/run/current-system/sw/bin"
              "/usr/bin"
              "/bin"
            ];
        in
          lib.nameValuePair "hermes-dashboard-${agent}"
          {
            Unit = {
              Description = "Hermes Agent Dashboard (${agent})";
              After = ["network-online.target" "hermes-agent-env.service"];
              Requires = ["hermes-agent-env.service"];
              Wants = ["network-online.target"];
            };

            Service = {
              Type = "simple";
              Environment = [
                "PATH=${lib.concatStringsSep ":" path}"
                "HERMES_HOME=${dataDir}/${agent}"
                "HERMES_KANBAN_HOME=${dataDir}"
                "HERMES_DASHBOARD_TUI=1"
              ];
              ExecStart = "${hermes} dashboard --no-open --port ${toString (dashboardPortFor agent)}";
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

            Install.WantedBy = ["default.target"];
          }
      )
      gatewayAgents);
  };
}
