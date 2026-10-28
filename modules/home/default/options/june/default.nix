# programs.june.enable = true;
{
  config,
  lib,
  perSystem,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.june;

  # The client finds the daemon's host here; a shell can still override it.
  daemonHostLine = lib.optionalString (cfg.daemonHost != null) "export JUNE_DAEMON_HOST=\"\${JUNE_DAEMON_HOST:-${cfg.daemonHost}}\"";
  # Run a writable checkout when one is installed, as the Emacs wrapper does, so
  # code changes need only a restart; otherwise run the pinned package. A host
  # without the checkout, or JUNE_SOURCE=none, runs the package.
  wrapper = pkgs.self.mkScript {
    name = "june";
    path = [pkgs.ripgrep pkgs.openssh];
    text =
      # bash
      ''
        ${daemonHostLine}
        source="''${JUNE_SOURCE:-${lib.optionalString (cfg.source != null) cfg.source}}"
        if [[ -n $source && -f $source/src/cli.ts && -d $source/node_modules ]]; then
          exec ${pkgs.nodejs_22}/bin/node --disable-warning=ExperimentalWarning "$source/src/cli.ts" "$@"
        fi
        exec ${perSystem.june.default}/bin/june "$@"
      '';
  };
in {
  # The daemon and the Org agent system each have their own file beside this one.
  imports = flake.lib.ls ./.;

  options.programs.june = {
    enable = lib.mkEnableOption "the june client";
    daemon.enable = lib.mkEnableOption "the June daemon on this host";
    dispatch.enable = lib.mkEnableOption "pi runs for Org agenda AUTO headings tagged with this host";
    package = lib.mkOption {
      type = lib.types.package;
      default = wrapper;
      readOnly = true;
      internal = true;
      description = "The june command, which the daemon's service also runs.";
    };
    source = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/jon/src/suderman/june";
      description = "A checkout of suderman/june that runs instead of the pinned package whenever it is installed (src/cli.ts and node_modules present). Optional; null always runs the package.";
    };
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
    telegram.allowedUsers = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [];
      description = "Telegram user ids allowed to talk to June; empty leaves Telegram off unless apiKeys sets TELEGRAM_ALLOWED_USERS.";
    };
  };

  config = lib.mkIf cfg.enable {
    # June works through pi agents in Herdr, and Org's own Emacs sets task states and dates for her and her agents.
    # A client-only host needs Herdr and Emacs for herdr-link and org-edit, but no pi.
    programs.pi-coding-agent.enable = lib.mkIf (cfg.daemon.enable || cfg.dispatch.enable) true;
    programs.herdr.enable = true;
    programs.emacs.enable = true;
    assertions = [
      {
        assertion = config.programs.herdr.package != null;
        message = "programs.june needs a Herdr package";
      }
    ];

    home.packages = [wrapper];

    # config.json and AGENTS.md reach ~/.config/june through agents apply; her own files are data.
    xdg.dataFile.june = lib.mkIf (cfg.dataDir != null) {
      source = config.lib.file.mkOutOfStoreSymlink cfg.dataDir;
    };
  };
}
