{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.herdr;
  self = config.networking.hostName;
  machines = lib.remove self cfg.workers;

  # Save each other worker as a Herdr machine on its running default session.
  # Without a terminal to ask in, machine add never installs or replaces a
  # server. Saved machines are skipped, so later runs need no SSH.
  saveMachines = pkgs.self.mkScript {
    name = "herdr-machines";
    path = [cfg.package pkgs.jq];
    text = ''
      saved=$(herdr machine list --json)
      status=0
      for machine in ${lib.escapeShellArgs machines}; do
        if ! jq -e --arg label "$machine" 'any(.[]; .label == $label)' <<<"$saved" >/dev/null; then
          herdr machine add "$machine" --remote-session default </dev/null || status=1
        fi
      done
      exit "$status"
    '';
  };
in {
  # Each worker lists the others; hosts outside the worker list keep none.
  config = lib.mkIf (cfg.enable && cfg.package != null && lib.elem self cfg.workers && machines != []) {
    # An asleep or offline worker retries later instead of blocking activation.
    systemd.user.services.herdr-machines = {
      Unit = {
        Description = "Save the other Herdr workers as machines";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe saveMachines;
        Restart = "on-failure";
        RestartSec = 300;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
