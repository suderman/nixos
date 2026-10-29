# programs.june.enable = true;
# The module is June's own (suderman/june, homeModules.default); this adds what only this flake has: agenix keys, pi's
# shared keys, persistence, and the pi, Herdr, and Emacs she works through.
{
  config,
  lib,
  flake,
  ...
}: let
  cfg = config.programs.june;
  home = config.home.homeDirectory;
  # pi's keys, materialized by its own service, when June shares them.
  piKeys = cfg.usePiKeys && config.programs.pi-coding-agent.apiKeys != null;
in {
  imports = [flake.inputs.june.homeModules.default];

  options.programs.june = {
    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Agenix secret of KEY=value lines for June's daemon alone: provider keys, TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOWED_USERS, and other integrations.";
    };
    usePiKeys = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Also load pi's API keys, beneath June's own, so the two share provider keys. False leaves June with apiKeys alone.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # June works through pi agents in Herdr, and Org's own Emacs sets task states and dates for her and her agents.
      # A client-only host needs Herdr and Emacs for herdr-link and org-edit, but no pi.
      programs.pi-coding-agent.enable = lib.mkIf (cfg.daemon.enable || cfg.dispatch.enable) true;
      programs.herdr.enable = true;
      programs.emacs.enable = true;
    }

    (lib.mkIf cfg.daemon.enable {
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

      # June's own keys load last, so they win over pi's shared ones.
      programs.june.environmentFiles =
        lib.optional piKeys "-${home}/.pi/agent/.env"
        ++ lib.optional (cfg.apiKeys != null) config.age.secrets.june-env.path;

      systemd.user.services.june = {
        Unit = {
          Wants = lib.optional piKeys "pi-coding-agent-env.service";
          Requires = lib.optional (cfg.apiKeys != null) "agenix.service";
          After =
            lib.optional piKeys "pi-coding-agent-env.service"
            ++ lib.optional (cfg.apiKeys != null) "agenix.service";
        };
        Service.Environment = ["SSH_AUTH_SOCK=%t/ssh-agent"];
      };
    })

    # Running tasks and settling headings must survive the root reset at boot.
    (lib.mkIf cfg.dispatch.enable {
      persist.scratch.directories = [".local/state/org-dispatch"];
    })
  ]);
}
