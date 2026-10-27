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
  # Run a writable checkout when one is installed, as the Emacs wrapper does, so
  # code changes need only a restart; otherwise run the pinned package.
  # JUNE_SOURCE=none forces the package.
  wrapper = pkgs.self.mkScript {
    name = "june";
    path = [pkgs.ripgrep pkgs.openssh];
    text =
      # bash
      ''
        export JUNE_CONFIG_PATH="''${JUNE_CONFIG_PATH:-${lib.concatStringsSep ":" cfg.configDirs}}"
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
    configDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # Harness defaults in Git, personal files synced by Syncthing, then this machine.
      default = ["${home}/.agents/june" "${home}/profile/june" "${config.xdg.configHome}/june"];
      description = "June's configuration layers, least specific first.";
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Agenix secret of KEY=value lines for June alone, such as her Telegram bot token.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [wrapper];

    # Conversation state; never synced, since Syncthing would copy a live SQLite WAL.
    persist.storage.directories = lib.mkIf cfg.daemon.enable [
      {
        directory = ".local/state/june";
        mode = "0700";
      }
    ];

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
        Environment = [
          "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
          "SSH_AUTH_SOCK=%t/ssh-agent"
        ];
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
