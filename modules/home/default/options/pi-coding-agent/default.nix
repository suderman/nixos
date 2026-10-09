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

  piStylixTheme = pkgs.self.mkScript {
    name = "pi-stylix-theme";
    path = [pkgs.coreutils];
    text = let
      palette = config.lib.stylix.colors.withHashtag;
      template = builtins.fromJSON (builtins.readFile "${flake.inputs.agents}/pi/themes/catppuccin-mocha.json");
      theme = pkgs.writeText "pi-stylix-theme.json" (builtins.toJSON (template
        // {
          name = "stylix";
          vars = {
            bg = palette.base00;
            panel = palette.base00;
            panelAlt = palette.base00;
            selected = palette.base01;
            border = palette.base02;
            accent = palette.base0D;
            cyan = palette.base0C;
            green = palette.base0B;
            red = palette.base08;
            yellow = palette.base0A;
            orange = palette.base09;
            purple = palette.base0E;
            text = palette.base05;
            muted = palette.base04;
            dim = palette.base03;
            toolSuccessBg = palette.base01;
            toolErrorBg = palette.base01;
          };
          export = {
            pageBg = "bg";
            cardBg = "panel";
            infoBg = "selected";
          };
        }));
    in ''
      target_dir="''${PI_CODING_AGENT_DIR:-${config.home.homeDirectory}/${agentDir}}/themes"
      target="$target_dir/stylix.json"
      if [[ ! -L "$target" && -f "$target" && -w "$target" ]] && cmp -s ${theme} "$target"; then
        exit 0
      fi
      mkdir -p -- "$target_dir"
      temporary="$(mktemp "$target.tmp.XXXXXX")"
      trap 'rm -f -- "$temporary"' EXIT
      cp -- ${theme} "$temporary"
      chmod 0644 -- "$temporary"
      mv -fT -- "$temporary" "$target"
    '';
  };

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
  imports = [./drop-zones.nix];

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

    # Preserve writable Pi theme files; bootstrap leaves this generated entry alone.
    home.activation.piStylixTheme = lib.mkIf config.stylix.enable (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${lib.getExe piStylixTheme}
      ''
    );

    home.activation.piHerdrIntegration = lib.mkIf (config.programs.herdr.enable && herdrPackage != null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD env \
          PI_CODING_AGENT_DIR=${config.home.homeDirectory}/${agentDir} \
          ${lib.getExe herdrPackage} integration install pi
      ''
    );

    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      pi-coding-agent-env.rekeyFile = cfg.apiKeys;
    };

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

    # Materialize API keys as the .env file pi expects. The wrapper restarts this
    # oneshot before loading .env so key changes are picked up opportunistically.
    systemd.user.services.pi-coding-agent-env = lib.mkIf (cfg.apiKeys != null) {
      Unit = {
        Description = "Generate pi-coding-agent .env";
        Requires = ["agenix.service"];
        After = ["agenix.service"];
      };

      Service = let
        keysEnv = config.age.secrets.pi-coding-agent-env.path;
        piDir = "${config.home.homeDirectory}/${agentDir}";
      in {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = pkgs.self.mkScript {
          text =
            # sh
            ''
              mkdir -p "${piDir}"

              if [ ! -r "${keysEnv}" ]; then
                echo "Missing pi-coding-agent agenix env file: ${keysEnv}" >&2
                exit 1
              fi

              tmp="$(mktemp "${piDir}/.env.tmp.XXXXXX")"
              cat "${keysEnv}" >"$tmp"
              chmod 600 "$tmp"
              mv "$tmp" "${piDir}/.env"
            '';
        };
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
