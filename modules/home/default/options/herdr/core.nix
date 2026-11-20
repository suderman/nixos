# herdr-core, the terminals agents run in, and its CLI hc. The Herdr app
# (programs.herdr, beside this file) is one of its clients.
{
  config,
  flake,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.services.herdr;
  hc = "${cfg.package}/bin/hc";
  desktop = config.desktop.enable or false;

  # Add each listed host once; saved machines are skipped, so later runs need
  # no SSH. machine add never installs hc there without a terminal to ask in.
  addMachines = pkgs.self.mkScript {
    name = "herdr-core-machines";
    path = [pkgs.jq];
    text = ''
      saved=$(${hc} machine ls --json)
      status=0
      for machine in ${lib.escapeShellArgs cfg.machines}; do
        if ! jq -e --arg name "$machine" 'any(.machines[]?; .name == $name)' <<<"$saved" >/dev/null; then
          ${hc} machine add "$machine" </dev/null || status=1
        fi
      done
      exit "$status"
    '';
  };
in {
  options.services.herdr = {
    enable = lib.mkEnableOption "herdr-core, its hc CLI, and a core started from the login session";
    package = lib.mkOption {
      type = lib.types.package;
      default = perSystem.herdr-nix.herdr-core;
      defaultText = lib.literalExpression "perSystem.herdr-nix.herdr-core";
      description = "The herdr-core package, which provides hc.";
    };
    machines = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["cog" "lux"];
      description = "Other hosts this core adds as hc machines, reached over SSH, so their terminals show here as HOST/t7.";
    };
  };

  config = lib.mkIf cfg.enable {
    # The TUI module already installs Edger when both are enabled.
    home.packages =
      [cfg.package]
      ++ lib.optional (!config.programs.herdr-tui.enable) (pkgs.self.mkScript {
        name = "edger";
        path = [cfg.package];
        text = builtins.readFile "${flake.inputs.edger}/bin/edger";
      });
    persist.storage.directories = [
      {
        directory = ".config/herdr-core";
        mode = "0700";
      }
    ];
    # Core stores layouts and machine records alongside unencrypted terminal history.
    persist.scratch.directories = [
      {
        directory = ".local/state/herdr-core";
        mode = "0700";
      }
    ];

    # Any hc command starts a core when none runs, and the core passes the
    # environment of whoever started it to every terminal: an SSH session
    # without WAYLAND_DISPLAY, or a service's narrow PATH. Start it here first,
    # from the login session, after the desktop's environment is imported.
    # The core itself runs in a transient unit of hc's own, so stopping or
    # renaming this one leaves it and its terminals alone.
    systemd.user.services.herdr-core = {
      Unit = {
        Description = "Start herdr-core with the login session's environment";
        After = lib.optional desktop "graphical-session.target";
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${hc} server start";
      };
      Install.WantedBy = [(if desktop then "graphical-session.target" else "default.target")];
    };

    # An asleep or offline host retries later instead of blocking login.
    systemd.user.services.herdr-core-machines = lib.mkIf (cfg.machines != []) {
      Unit = {
        Description = "Add the other hosts as hc machines";
        After = ["herdr-core.service"];
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe addMachines;
        Restart = "on-failure";
        RestartSec = 300;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
