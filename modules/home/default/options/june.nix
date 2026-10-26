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
  wrapper = pkgs.self.mkScript {
    name = "june";
    text =
      # bash
      ''
        export JUNE_CONFIG_PATH="''${JUNE_CONFIG_PATH:-${lib.concatStringsSep ":" cfg.configDirs}}"
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

    systemd.user.services.june = lib.mkIf cfg.daemon.enable {
      Unit = {
        Description = "June personal assistant";
        # June uses Pi's provider definitions and its agenix-generated keys.
        Wants = ["network-online.target" "pi-coding-agent-env.service"];
        After = ["network-online.target" "pi-coding-agent-env.service"];
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe wrapper} serve";
        EnvironmentFile = "-${home}/.pi/agent/.env";
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
