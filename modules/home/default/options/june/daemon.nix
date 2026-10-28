# programs.june.daemon.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.june;
  home = config.home.homeDirectory;
  # pi's keys, materialized by its own service, when June shares them.
  piKeys = cfg.usePiKeys && config.programs.pi-coding-agent.apiKeys != null;
in {
  config = lib.mkIf (cfg.enable && cfg.daemon.enable) {
    # Conversation state; never synced, since Syncthing would copy a live SQLite WAL.
    persist.storage.directories =
      [
        {
          directory = ".local/state/june";
          mode = "0700";
        }
      ]
      ++ lib.optional (cfg.dataDir == null) {
        directory = ".local/share/june";
        mode = "0700";
      };

    age.secrets.june-env = lib.mkIf (cfg.apiKeys != null) {
      rekeyFile = cfg.apiKeys;
    };

    systemd.user.services.june = {
      Unit = {
        Description = "June personal assistant";
        Wants = ["network-online.target"] ++ lib.optional piKeys "pi-coding-agent-env.service";
        Requires = lib.optional (cfg.apiKeys != null) "agenix.service";
        After =
          ["network-online.target"]
          ++ lib.optional piKeys "pi-coding-agent-env.service"
          ++ lib.optional (cfg.apiKeys != null) "agenix.service";
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} serve";
        # June's own keys load last, so they win over pi's shared ones.
        EnvironmentFile =
          lib.optional piKeys "-${home}/.pi/agent/.env"
          ++ lib.optional (cfg.apiKeys != null) config.age.secrets.june-env.path;
        # Herdr, org-dispatch, Emacs, and ssh come from the profile and system.
        Environment =
          [
            "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
            "SSH_AUTH_SOCK=%t/ssh-agent"
          ]
          ++ lib.optional (cfg.telegram.allowedUsers != []) "TELEGRAM_ALLOWED_USERS=${lib.concatMapStringsSep "," toString cfg.telegram.allowedUsers}";
        Restart = "on-failure";
        RestartSec = 5;
        # SIGTERM closes Telegram and the harness; unfinished work resumes on the next start.
        TimeoutStopSec = 30;
        UMask = "0077";
        NoNewPrivileges = true;
        # No PrivateTmp or ProtectSystem: in a user unit they add a user namespace in which
        # store-owned files look owned by nobody, and ssh then refuses ~/.ssh/config.
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
