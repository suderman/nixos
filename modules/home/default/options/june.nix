# programs.june.enable = true;
{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.june;
  home = config.home.homeDirectory;
  # The client finds the daemon's host here; a shell can still override it.
  daemonHostLine = lib.optionalString (cfg.daemonHost != null) "export JUNE_DAEMON_HOST=\"\${JUNE_DAEMON_HOST:-${cfg.daemonHost}}\"";
  # Run a writable checkout when one is installed, as the Emacs wrapper does, so
  # code changes need only a restart; otherwise run the pinned package.
  # JUNE_SOURCE=none forces the package.
  wrapper = pkgs.self.mkScript {
    name = "june";
    path = [pkgs.ripgrep pkgs.openssh];
    text =
      # bash
      ''
        ${daemonHostLine}
        source="''${JUNE_SOURCE:-${home}/src/suderman/june}"
        if [[ -f $source/src/cli.ts && -d $source/node_modules ]]; then
          exec ${pkgs.nodejs_22}/bin/node --disable-warning=ExperimentalWarning "$source/src/cli.ts" "$@"
        fi
        exec ${perSystem.june.default}/bin/june "$@"
      '';
  };
in {
  options.programs.june = {
    enable = lib.mkEnableOption "the june client";
    daemon.enable = lib.mkEnableOption "the June daemon on this host";
    daemonHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The host that runs June's daemon; june on any other host runs there over SSH.";
    };
    dataDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/jon/org/june";
      description = "Where June's SOUL.org, MEMORY.org, and JOURNAL.org really live; ~/.local/share/june links there. Null keeps them in ~/.local/share/june itself.";
    };
    telegram.allowedUsers = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [];
      description = "Telegram user ids allowed to talk to June; empty leaves Telegram off unless envFile sets TELEGRAM_ALLOWED_USERS.";
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Agenix secret of KEY=value lines for June alone, such as her Telegram bot token.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [wrapper];

    # config.json and AGENTS.md reach ~/.config/june through agents apply; her own files are data.
    xdg.dataFile.june = lib.mkIf (cfg.dataDir != null) {
      source = config.lib.file.mkOutOfStoreSymlink cfg.dataDir;
    };

    # Conversation state; never synced, since Syncthing would copy a live SQLite WAL.
    persist.storage.directories = lib.mkIf cfg.daemon.enable (
      [
        {
          directory = ".local/state/june";
          mode = "0700";
        }
      ]
      ++ lib.optional (cfg.dataDir == null) {
        directory = ".local/share/june";
        mode = "0700";
      }
    );

    age.secrets.june-env = lib.mkIf (cfg.daemon.enable && cfg.envFile != null) {
      rekeyFile = cfg.envFile;
    };

    systemd.user.services.june = lib.mkIf cfg.daemon.enable {
      Unit = {
        Description = "June personal assistant";
        # June uses Pi's provider definitions and its agenix-generated keys, plus her own secret.
        Wants = ["network-online.target" "pi-coding-agent-env.service"];
        Requires = lib.optional (cfg.envFile != null) "agenix.service";
        After = ["network-online.target" "pi-coding-agent-env.service"] ++ lib.optional (cfg.envFile != null) "agenix.service";
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe wrapper} serve";
        # June's own secret loads last, so its keys win over the shared ones.
        EnvironmentFile = ["-${home}/.pi/agent/.env"] ++ lib.optional (cfg.envFile != null) config.age.secrets.june-env.path;
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
