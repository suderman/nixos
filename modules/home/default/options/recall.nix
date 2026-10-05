{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.services.recall;
in {
  options.services.recall = {
    enable = lib.mkEnableOption "Recall CLI and persistent data";
    bluebubbles.enable = lib.mkEnableOption "Recall BlueBubbles capture";
    package = lib.mkOption {
      type = lib.types.package;
      default = perSystem.recall.default;
      description = "Recall CLI package.";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = ".local/share/recall";
      description = "Recall data directory relative to the home directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];
    persist.storage.directories = [
      {
        directory = cfg.dataDir;
        mode = "0700";
      }
    ];

    # Keep the private source config and acquired bytes outside the Nix store.
    # The existing config must bind to 127.0.0.1:8042 and require its webhook token.
    systemd.user.services = let
      hardening = {
        UMask = "0077";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
      };
    in
      lib.mkIf cfg.bluebubbles.enable {
        recall-bluebubbles = {
          Unit = {
            Description = "Recall BlueBubbles webhook receiver";
            After = ["network-online.target"];
            Wants = ["network-online.target"];
            ConditionPathExists = "${config.home.homeDirectory}/${cfg.dataDir}/bluebubbles/config/sources/bluebubbles.toml";
            StartLimitIntervalSec = 60;
            StartLimitBurst = 5;
          };
          Service =
            hardening
            // rec {
              Type = "simple";
              WorkingDirectory = "${config.home.homeDirectory}/${cfg.dataDir}/bluebubbles";
              ExecStart = "${cfg.package}/bin/recall capture bluebubbles serve --skip-recovery --root ${WorkingDirectory}";
              UnsetEnvironment = "PYTHONPATH";
              Restart = "on-failure";
              RestartSec = 5;
              # Persistence bind mounts need both paths writable inside the sandbox.
              ReadWritePaths = ["${config.home.homeDirectory}/${cfg.dataDir}" "${config.persist.storage.path}/${cfg.dataDir}"];
            };
          Install.WantedBy = ["default.target"];
        };

        recall-bluebubbles-tunnel = {
          Unit = {
            Description = "Recall BlueBubbles loopback SSH tunnel";
            After = ["network-online.target" "ssh-agent.service" "recall-bluebubbles.service"];
            Wants = ["network-online.target" "ssh-agent.service" "recall-bluebubbles.service"];
            StartLimitIntervalSec = 60;
            StartLimitBurst = 5;
          };
          Service =
            hardening
            // {
              Type = "simple";
              Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
              ExecStart = "${pkgs.openssh}/bin/ssh -F /dev/null -i %h/.ssh/id_ed25519 -i %h/.ssh/id_rsa -o IdentitiesOnly=yes -S none -o ControlMaster=no -o BatchMode=yes -o StrictHostKeyChecking=yes -o RemoteCommand=none -o ExitOnForwardFailure=yes -o ConnectTimeout=10 -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -N -R 127.0.0.1:8042:127.0.0.1:8042 bub";
              Restart = "on-failure";
              RestartSec = 15;
            };
          Install.WantedBy = ["default.target"];
        };
      };
  };
}
