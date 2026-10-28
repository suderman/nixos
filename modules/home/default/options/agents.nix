# programs.agents.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  command = pkgs.self.mkScript {
    name = "agents";
    path = with pkgs; [bash coreutils git jq python3 yq-go];
    text = ''
      if [[ ! -f "$HOME/.agents/agents" ]]; then
        echo "Missing agents checkout at $HOME/.agents; start agents-checkout.service or clone https://github.com/suderman/agents.git there." >&2
        exit 1
      fi
      exec python3 "$HOME/.agents/agents" "$@"
    '';
  };
  checkout = pkgs.self.mkScript {
    name = "agents-checkout";
    path = [pkgs.coreutils pkgs.git];
    text = ''
      repository="$HOME/.agents"
      if [[ -d "$repository/.git" || -f "$repository/.git" ]]; then
        exit 0
      fi
      if [[ -e "$repository" || -L "$repository" ]]; then
        if [[ ! -d "$repository" || -n "$(ls -A -- "$repository")" ]]; then
          echo "Refusing to replace nonempty agents path: $repository" >&2
          exit 78
        fi
      fi
      timeout 120 git clone https://github.com/suderman/agents.git "$repository"
    '';
  };
in {
  options.programs.agents.enable = lib.mkEnableOption "the writable portable agents checkout and CLI";

  config = lib.mkIf cfg.enable {
    persist.storage.directories = [".agents"];
    home.packages = [command];

    # Type=exec completes the start job before Git runs, so sd-switch does not wait.
    # Updating and deploying remain explicit CLI jobs.
    systemd.user.services.agents-checkout = {
      Unit = {
        Description = "Install the portable agents checkout if absent";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "exec";
        RemainAfterExit = true;
        Environment = "GIT_TERMINAL_PROMPT=0";
        ExecStart = lib.getExe checkout;
        Restart = "on-failure";
        RestartSec = 30;
        RestartPreventExitStatus = 78;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
