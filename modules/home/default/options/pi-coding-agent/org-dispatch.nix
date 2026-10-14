{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.pi-coding-agent;
  herdrPackage = config.programs.herdr.package;

  # Source lives in suderman/agents under org/; prompts come from the same pin.
  orgSource = "${flake.inputs.agents}/org";

  orgDispatch = pkgs.self.mkScript {
    name = "org-dispatch";
    path = [config.programs.emacs.finalPackage herdrPackage pkgs.git pkgs.util-linux];
    env = {
      TZDIR = "${pkgs.tzdata}/share/zoneinfo";
      ORG_DISPATCH_EL = "${orgSource}/dispatch/org-dispatch.el";
      ORG_DISPATCH_PROMPTS = "${orgSource}/prompts";
    };
    text = builtins.readFile "${orgSource}/dispatch/org-dispatch";
  };
in {
  options.programs.pi-coding-agent.orgDispatch.enable = lib.mkEnableOption "pi runs for Org agenda AUTO headings tagged with this host";

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
