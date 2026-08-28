{
  config,
  lib,
  ...
}: let
  cfg = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) apiPort dataDir;
  path =
    config.home.sessionPath
    ++ [
      "${config.home.profileDirectory}/bin"
      "/run/current-system/sw/bin"
      "/usr/bin"
      "/bin"
    ];
in {
  config = lib.mkIf (cfg.enable && cfg.gateway.enable) {
    systemd.user.services.hermes-gateway = {
      Unit = {
        Description = "Hermes Agent multiplex gateway";
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
          "API_SERVER_PORT=${toString apiPort}"
          "API_SERVER_ENABLED=1"
        ];
        ExecStart = "${cfg.package}/bin/hermes gateway run --replace";
        Restart = "always";
        RestartSec = 5;
        TimeoutStopSec = 210;
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
