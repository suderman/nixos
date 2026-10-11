{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.pi-coding-agent;
  herdrPackage = config.programs.herdr.package;

  orgDispatch = pkgs.self.mkScript {
    name = "org-dispatch";
    path = [config.programs.emacs.finalPackage herdrPackage pkgs.git pkgs.util-linux];
    env = {
      TZDIR = "${pkgs.tzdata}/share/zoneinfo";
      ORG_DISPATCH_EL = "${./org-dispatch.el}";
    };
    text =
      # bash
      ''
        # Run autonomous Org tasks with pi in Herdr.
        #
        #   org-dispatch [run]                 watch running tasks, then launch eligible ones
        #   org-dispatch scan                  list tasks this host would launch now
        #   org-dispatch finish ID STATE NOTE  end a task as EVAL, HOLD, or DONE
        batch=(emacs -Q --batch -l "$ORG_DISPATCH_EL")

        case ''${1:-run} in
          run) exec flock -n "''${XDG_RUNTIME_DIR:-/tmp}/org-dispatch.lock" "''${batch[@]}" -f org-dispatch-run ;;
          scan) exec "''${batch[@]}" -f org-dispatch-scan ;;
          finish)
            [[ $# -ge 3 ]] || { echo "usage: org-dispatch finish ID EVAL|HOLD|DONE [NOTE]" >&2; exit 2; }
            shift
            exec "''${batch[@]}" -f org-dispatch-finish "$@"
            ;;
          *) echo "usage: org-dispatch [run|scan|finish ID STATE [NOTE]]" >&2; exit 2 ;;
        esac
      '';
  };
in {
  options.programs.pi-coding-agent.orgDispatch.enable = lib.mkEnableOption "pi runs for first-level Org TODO headings tagged with this host and :auto:";

  config = lib.mkIf (cfg.enable && cfg.orgDispatch.enable) {
    assertions = [
      {
        assertion = config.programs.herdr.enable && herdrPackage != null && config.programs.emacs.enable;
        message = "programs.pi-coding-agent.orgDispatch requires programs.herdr and programs.emacs";
      }
    ];

    # Agents call org-dispatch finish, so it must be on PATH in Herdr panes.
    home.packages = [orgDispatch];

    # Running tasks and settling headings must survive the root reset at boot.
    persist.scratch.directories = [".local/state/org-dispatch"];

    systemd.user.services.org-dispatch = {
      Unit.Description = "Dispatch autonomous Org tasks to pi in Herdr";
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe orgDispatch} run";
      };
    };

    systemd.user.timers.org-dispatch = {
      Unit.Description = "Check Org for autonomous tasks every minute";
      Timer = {
        OnCalendar = "minutely";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
