# programs.june.enable = true;
# The module is June's own (suderman/june, homeModules.default); this adds what only this flake has: agenix keys, pi's
# shared keys, persistence, and the pi, herdr-core, and Emacs she works through.
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
      # June works through pi and Claude agents in herdr-core (hc), and Org's own Emacs sets task states and dates for
      # her and her agents. A client-only host needs hc and Emacs for herdr-link and org-edit, but no pi.
      programs.pi-coding-agent.enable = lib.mkIf (cfg.daemon.enable || cfg.dispatch.enable) true;
      services.herdr.enable = true;
      programs.june.hcPackage = lib.mkDefault config.services.herdr.finalPackage;
      # The same ntfy topic the Herdr TUI's herdr-ntfy plugin posted to.
      programs.june.notify.url = lib.mkDefault "https://ntfy.hub/herdr";
      programs.emacs.enable = true;

      # adb's host key, which the phone authorized, and the debug keystore June's `nix run .#android-install` signs
      # with. Every host that installs June's app must hold the same keystore: copy it between hosts once, since an
      # app signed with another key cannot be updated, only uninstalled.
      persist.storage.directories = [
        {
          directory = ".android";
          mode = "0700";
        }
      ];
    }

    (lib.mkIf (cfg.daemon.enable || cfg.accounts.enable) {
      # Conversation state, and on account hosts the numbered harness logins (june accounts); never synced, since
      # Syncthing would copy a live SQLite WAL. config.json and AGENTS.md come from agents apply, which replaces them by
      # rename, so the directory persists, not the files; the account counts are in config.json.
      persist.storage.directories = [
        ".config/june"
        {
          directory = ".local/state/june";
          mode = "0700";
        }
      ];
    })

    (lib.mkIf cfg.daemon.enable {
      persist.storage.directories = lib.optional (cfg.dataDir == null) {
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
          Wants = ["herdr.service"] ++ lib.optional piKeys "pi-coding-agent-env.service";
          Requires = lib.optional (cfg.apiKeys != null) "agenix.service";
          After =
            ["herdr.service"]
            ++ lib.optional piKeys "pi-coding-agent-env.service"
            ++ lib.optional (cfg.apiKeys != null) "agenix.service";
        };
        Service.Environment = ["SSH_AUTH_SOCK=%t/${config.programs.ssh.agentSocket}"];
      };
    })

    (lib.mkIf cfg.notify.watch {
      systemd.user.services.herdr-notify.Unit = {
        Wants = ["herdr.service"];
        After = ["herdr.service"];
      };
    })

    # Running tasks and settling headings must survive the root reset at boot.
    (lib.mkIf cfg.dispatch.enable {
      systemd.user.services.org-dispatch.Unit.After = ["herdr.service"];
      persist.scratch.directories = [".local/state/org-dispatch"];
      # Each host where agents work tidies its own org-work folders weekly (june org-work --clean).
      programs.june.orgWork = {
        enable = lib.mkDefault true;
        keep = ["%h/org/june/avatar" "%h/org/work/suderman/june/art.org"];
        record = "%h/org/work/suderman/june/2026-11-21-org-work-cleanup/%H.org";
      };
    })
  ]);
}
