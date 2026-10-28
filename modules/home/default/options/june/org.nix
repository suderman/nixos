# programs.june.dispatch.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.june;
  herdrPackage = config.programs.herdr.package;

  # June owns the Org agent system: the dispatcher, org-edit, herdr-link, and their prompts, all from the same pin.
  orgSource = "${flake.inputs.june}/org";

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

  # Agents set TODO states and dates through Org rather than editing text.
  orgEdit = pkgs.self.mkScript {
    name = "org-edit";
    path = [config.programs.emacs.finalPackage];
    env = {
      TZDIR = "${pkgs.tzdata}/share/zoneinfo";
      ORG_EDIT_EL = "${orgSource}/edit/org-edit.el";
      ORG_DISPATCH_EL = "${orgSource}/dispatch/org-dispatch.el";
    };
    text = builtins.readFile "${orgSource}/edit/org-edit";
  };

  # Org links to agent sessions; jump expects Hyprland and kitty on the desktop.
  herdrLink = pkgs.self.mkScript {
    name = "herdr-link";
    path = with pkgs; [herdrPackage jq openssh procps gawk gnugrep gnused util-linux];
    text = builtins.readFile "${orgSource}/bin/herdr-link";
  };
in {
  config = lib.mkIf cfg.enable {
    # Agents call org-edit, herdr-link, and org-dispatch finish, so they must be on PATH in Herdr panes.
    home.packages = [orgEdit herdrLink] ++ lib.optional cfg.dispatch.enable orgDispatch;

    # The pinned project-org-tasks and org-triage, which agents apply links into ~/.agents/skills when no checkout
    # of June is here to take precedence.
    xdg.configFile."june/skills".source = "${flake.inputs.june}/skills";

    # Running tasks and settling headings must survive the root reset at boot.
    persist.scratch.directories = lib.mkIf cfg.dispatch.enable [".local/state/org-dispatch"];

    systemd.user.services.org-dispatch = lib.mkIf cfg.dispatch.enable {
      Unit.Description = "Dispatch autonomous Org tasks to pi in Herdr";
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe orgDispatch} run";
      };
    };

    systemd.user.timers.org-dispatch = lib.mkIf cfg.dispatch.enable {
      Unit.Description = "Check Org for autonomous tasks every minute";
      Timer = {
        OnCalendar = "minutely";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
