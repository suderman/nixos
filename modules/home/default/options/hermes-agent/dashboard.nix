{
  config,
  lib,
  ...
}: let
  cfg = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) dashboardPort dataDir;
  path =
    config.home.sessionPath
    ++ [
      "${config.home.profileDirectory}/bin"
      "/run/current-system/sw/bin"
      "/usr/bin"
      "/bin"
    ];
in {
  config = lib.mkIf (cfg.enable && cfg.dashboard.enable) {
    systemd.user.services.hermes-dashboard = {
      Unit = {
        Description = "Hermes Agent machine dashboard";
        After = ["default.target" "hermes-agent-env.service"];
        Requires = ["hermes-agent-env.service"];
        X-Restart-Triggers = config.systemd.user.services.hermes-agent-env.Service.ExecStart;
      };

      Service = {
        Type = "simple";
        Environment = [
          "PATH=${lib.concatStringsSep ":" path}"
          "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
          "REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt"
          "HERMES_HOME=${dataDir}"
          "HERMES_KANBAN_HOME=${dataDir}"
          "HERMES_MANAGED=home-manager"
          "HERMES_DASHBOARD_TUI=1"
        ];
        ExecStart = "${cfg.package}/bin/hermes dashboard --no-open --port ${toString dashboardPort}";
        Restart = "always";
        RestartSec = 5;
        TimeoutStopSec = 30;
        TimeoutStartSec = 30;
        SuccessExitStatus = "0 143";
        KillMode = "control-group";
        UMask = "0077";
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
    };
  };
}
