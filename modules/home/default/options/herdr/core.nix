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
  rawHc = "${cfg.package}/bin/hc";
  hmSessionVars = "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh";
  desktop = config.desktop.enable or false;

  # Terminals inherit the core's environment for good, and at boot or login systemd
  # may not have the session's PATH yet (e.g. ~/.local/bin for June's harness wrappers).
  # Load Home Manager's session variables before starting or refreshing the core, then
  # clear __HM_SESS_VARS_SOURCED: systemd omits __NIXOS_SET_ENVIRONMENT_DONE, so child
  # zsh panes source /etc/set-environment (which overwrites PATH) and need ~/.zshenv's
  # hm-session-vars.sh to run again to restore home.sessionPath.
  herdrStart = pkgs.writeShellScript "herdr-start" ''
    export PATH="''${PATH:+$PATH:}${pkgs.coreutils}/bin"
    unset __HM_SESS_VARS_SOURCED
    . "${hmSessionVars}"
    unset __HM_SESS_VARS_SOURCED
    exec ${rawHc} server start
  '';

  herdrSession = pkgs.writeShellScript "herdr-session" ''
    export PATH="''${PATH:+$PATH:}${pkgs.coreutils}/bin"
    unset __HM_SESS_VARS_SOURCED
    . "${hmSessionVars}"
    unset __HM_SESS_VARS_SOURCED
    exec ${rawHc} server restart --fresh
  '';

  # Any hc/herdr-core client auto-starts a core when none runs, capturing the
  # caller's environment (a service's narrow PATH or an SSH shell). Route missing
  # default-session starts through herdr.service so the core always inherits
  # systemd's user environment plus hm-session-vars.sh.
  wrappedBin = name:
    pkgs.writeShellScript name ''
      ensure_core() {
        [[ -z ''${HC_SOCKET-} && (-z ''${HC_SESSION-} || ''${HC_SESSION} == default) ]] || return 0
        local cmd=''${1-} sub=''${2-}
        if [[ $cmd == --json ]]; then
          cmd=''${2-}
          sub=''${3-}
        fi
        case $cmd in
          serve | hold | help | -h | --help | -V | --version | --skill | --licenses) return 0 ;;
          server)
            case $sub in
              "" | start | stop | restart | help | -h | --help) return 0 ;;
            esac
            ;;
        esac
        local sock="''${XDG_RUNTIME_DIR:-/run/user/$UID}/herdr-core/default.sock"
        [[ -S $sock ]] && return 0
        if ! ${pkgs.systemd}/bin/systemctl --user start herdr.service </dev/null >/dev/null 2>&1; then
          unset __HM_SESS_VARS_SOURCED
          if [[ -r "${hmSessionVars}" ]]; then
            export PATH="''${PATH:+$PATH:}${pkgs.coreutils}/bin"
            . "${hmSessionVars}" </dev/null >/dev/null 2>&1
            unset __HM_SESS_VARS_SOURCED
          fi
        fi
      }
      ensure_core "$@"
      exec ${cfg.package}/bin/${name} "$@"
    '';

  wrapped =
    pkgs.runCommand "herdr-core-wrapped" {
      meta.mainProgram = "herdr-core";
    } ''
      mkdir -p "$out/bin"
      ln -s ${wrappedBin "hc"} "$out/bin/hc"
      ln -s ${wrappedBin "herdr-core"} "$out/bin/herdr-core"
    '';

  hc = "${wrapped}/bin/hc";

  # Add each listed host once; saved machines are skipped, so later runs need
  # no SSH. machine add never installs hc there without a terminal to ask in.
  # A target such as jon@kit is saved under its host name, kit.
  addMachines = pkgs.self.mkScript {
    name = "herdr-machines";
    path = [pkgs.jq];
    text = ''
      saved=$(${hc} machine ls --json)
      status=0
      for machine in ${lib.escapeShellArgs cfg.machines}; do
        name=''${machine##*@}
        if ! jq -e --arg name "$name" 'any(.machines[]?; .name == $name)' <<<"$saved" >/dev/null; then
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
    finalPackage = lib.mkOption {
      type = lib.types.package;
      default = wrapped;
      readOnly = true;
      description = "The wrapped herdr-core package whose hc and herdr-core commands route cold starts through herdr.service.";
    };
    machines = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["cog" "jon@lux"];
      description = "Other hosts this core adds as hc machines, reached over SSH, so their terminals show here as HOST/t7. Prefix USER@ to reach another account there.";
    };
  };

  config = lib.mkIf cfg.enable {
    # The TUI module already installs Edger when both are enabled.
    home.packages =
      [wrapped]
      ++ lib.optional (!config.programs.herdr-tui.enable) (pkgs.self.mkScript {
        name = "edger";
        path = [wrapped];
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

    # Start the core at default.target so boot-time services (herdr-notify,
    # herdr-machines, org-dispatch, june) and remote SSH clients find a core
    # that already has the Home Manager session PATH (~/.local/bin, etc.).
    # Omit RemainAfterExit so later `systemctl --user start herdr.service`
    # calls from the hc wrapper still start a stopped core. The core itself
    # runs in a transient unit of hc's own, so this unit exiting leaves it alone.
    systemd.user.services.herdr = {
      Unit = {
        Description = "Start herdr-core with the Home Manager session environment";
      };
      Service = {
        Type = "oneshot";
        ExecStart = toString herdrStart;
      };
      Install.WantedBy = ["default.target"];
    };

    # On desktop hosts, refresh the core's environment once the graphical session
    # imports display variables; --fresh keeps already-running terminals alive.
    systemd.user.services.herdr-session = lib.mkIf desktop {
      Unit = {
        Description = "Refresh herdr-core with the graphical session's environment";
        After = ["graphical-session.target" "herdr.service"];
        PartOf = ["graphical-session.target"];
        Requisite = ["graphical-session.target"];
        X-RestartIfChanged = false;
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = toString herdrSession;
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    # Boot-restored panes start when herdr-core starts at default.target, before
    # Hyprland exports display variables, and --fresh only updates new terminals.
    # Import display variables on demand in existing zsh shells once systemd has them.
    programs.zsh.initContent = lib.mkIf (desktop && config.programs.zsh.enable) (
      lib.mkAfter ''
        _herdr_import_display_env() {
          [[ -n ''${WAYLAND_DISPLAY-} || -n ''${SSH_CONNECTION-} ]] && return 0
          local line key val
          while IFS= read -r line; do
            case $line in
              WAYLAND_DISPLAY=* | DISPLAY=* | XDG_SESSION_TYPE=*)
                key=''${line%%=*}
                val=''${line#*=}
                [[ -z ''${(P)key-} && -n $val ]] && export "$key=$val"
                ;;
            esac
          done < <(command systemctl --user show-environment 2>/dev/null)
          return 0
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook preexec _herdr_import_display_env
      ''
    );

    # An asleep or offline host retries later instead of blocking login.
    systemd.user.services.herdr-machines = lib.mkIf (cfg.machines != []) {
      Unit = {
        Description = "Add the other hosts as hc machines";
        Wants = ["herdr.service"];
        After = ["herdr.service"];
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
