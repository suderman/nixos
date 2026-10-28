# programs.pi-coding-agent.enable = true;
{
  config,
  flake,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.pi-coding-agent;

  agentDir = ".pi/agent";
  herdrPackage = config.programs.herdr.package;

  piDcpPackageFix = pkgs.self.mkScript {
    name = "pi-fix-dcp-package";
    path = [pkgs.coreutils pkgs.jq];
    text = builtins.readFile "${flake.inputs.agents}/pi/fix-dcp-package";
  };

  # Load secrets and fix extension metadata without changing native runtime paths.
  pi-init = pkgs.self.mkScript {
    name = "pi";
    path = [pkgs.systemd];
    text =
      # bash
      ''
        pi_dir="''${PI_CODING_AGENT_DIR:-$HOME/${agentDir}}"
        ${lib.getExe piDcpPackageFix}

        if systemctl --user --quiet is-enabled pi-coding-agent-env.service 2>/dev/null; then
          systemctl --user restart pi-coding-agent-env.service || true
        fi

        set -a
        [[ -f "$pi_dir/.env" ]] && . "$pi_dir/.env"
        [[ -f "$pi_dir/.env.local" ]] && . "$pi_dir/.env.local"
        set +a

        exec ${perSystem.agents.pi}/bin/pi "$@"
      '';
  };
in {
  # API keys and the Stylix theme each have their own file beside this one.
  imports = flake.lib.ls ./.;

  options.programs.pi-coding-agent = {
    enable = lib.mkEnableOption "pi-coding-agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pi-init;
      description = "Pi wrapper package.";
    };

    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to multi-line .env file with API keys such as ANTHROPIC_API_KEY.";
    };
  };

  config = lib.mkIf cfg.enable {
    toolchains.javascript.enable = true;

    persist.storage.directories = [agentDir ".pi-lens" ".config/pi"];
    # Retain legacy state for rollback, never activation-time moves.
    persist.scratch.directories = [".local/state/pi"];

    # Put the wrapper at the conventional user-bin path without exposing the
    # implementation package name to callers.
    home.file.".local/bin/pi".source = "${cfg.package}/bin/pi";

    home.activation.piHerdrIntegration = lib.mkIf (config.programs.herdr.enable && herdrPackage != null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD env \
          PI_CODING_AGENT_DIR=${config.home.homeDirectory}/${agentDir} \
          ${lib.getExe herdrPackage} integration install pi
      ''
    );

    systemd.user.services.pi-extension-update = {
      Unit.Description = "Update Pi extensions";
      Service = {
        Type = "oneshot";
        TimeoutStartSec = "30min";
        Environment = "GIT_TERMINAL_PROMPT=0";
        ExecStart = "${cfg.package}/bin/pi update --extensions --no-approve";
      };
    };

    systemd.user.timers.pi-extension-update = {
      Unit.Description = "Update Pi extensions daily";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "2h";
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
