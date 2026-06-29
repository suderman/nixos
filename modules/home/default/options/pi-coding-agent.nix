# programs.pi-coding-agent.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.pi-coding-agent;
  cfgDir = ".pi";
  agentDir = "${cfgDir}/agent";

  pi-init = pkgs.self.mkScript {
    name = "pi";
    path = [pkgs.git pkgs.nodejs pkgs.systemd];
    text =
      # bash
      ''
        export NPM_CONFIG_PREFIX="${config.home.sessionVariables.NPM_CONFIG_PREFIX}"
        export NPM_CONFIG_CACHE="${config.home.sessionVariables.NPM_CONFIG_CACHE}"

        PI_BIN="''${PI_BIN:-${config.home.sessionVariables.NPM_CONFIG_PREFIX}/bin/pi}"
        PI_CONFIG_DIR="''${PI_CONFIG_DIR:-${config.home.homeDirectory}/${cfgDir}}"
        PI_DIR="''${PI_DIR:-${config.home.homeDirectory}/${agentDir}}"
        PI_INIT_STAMP="''${PI_INIT_STAMP:-${config.home.homeDirectory}/.local/state/pi-coding-agent/init.timestamp}"
        PI_INIT_INTERVAL="$((24 * 60 * 60))"

        pi_env_init() {
          if systemctl --user --quiet is-enabled pi-coding-agent-env.service 2>/dev/null; then
            systemctl --user restart pi-coding-agent-env.service || true
          fi
        }

        pi_env_load() {
          set -a
          [[ -f "$PI_DIR/.env" ]] && . "$PI_DIR/.env"
          [[ -f "$PI_DIR/.env.local" ]] && . "$PI_DIR/.env.local"
          set +a
        }

        pi_config_init() {
          if [[ ! -d "$PI_CONFIG_DIR/.git" ]]; then
            if [[ -z "$PI_CONFIG_DIR" || "$PI_CONFIG_DIR" == "/" || "$PI_CONFIG_DIR" == "${config.home.homeDirectory}" ]]; then
              echo "Refusing to reset unsafe pi-coding-agent config directory: $PI_CONFIG_DIR" >&2
              exit 1
            fi

            mkdir -p "$PI_CONFIG_DIR"
            shopt -s dotglob nullglob
            rm -rf "$PI_CONFIG_DIR"/*
            shopt -u dotglob nullglob

            tmp="$(mktemp -d)"
            git clone "${cfg.gitUrl}" "$tmp"
            cp -a "$tmp"/. "$PI_CONFIG_DIR"/
            rm -rf "$tmp"
          fi

          if [[ ! -d "$PI_CONFIG_DIR/.git" ]]; then
            echo "Failed to clone pi-coding-agent configuration" >&2
            exit 1
          fi
        }

        pi_init() {
          pi_config_init
          mkdir -p "$PI_DIR"
          npm i -g --ignore-scripts @earendil-works/pi-coding-agent

          # Also install hypa
          npm i -g @hypabolic/hypa

          if [[ ! -f "$PI_BIN" ]]; then
            echo "Failed to install pi binary" >&2
            exit 1
          fi

          mkdir -p "$(dirname "$PI_INIT_STAMP")"
          date +%s >"$PI_INIT_STAMP"
        }

        pi_init_stale() {
          [[ ! -f "$PI_INIT_STAMP" ]] && return 0

          local now last
          now="$(date +%s)"
          last="$(<"$PI_INIT_STAMP")"

          [[ ! "$last" =~ ^[0-9]+$ ]] && return 0
          ((now - last >= PI_INIT_INTERVAL))
        }

        if [[ "''${1:-}" == "init" ]]; then
          pi_init
          pi_env_init
          exit 0
        fi

        if [[ ! -e "$PI_BIN" ]] || pi_init_stale; then
          pi_init
        fi

        pi_env_init
        pi_env_load

        exec "$PI_BIN" "$@"
      '';
  };
in {
  options.programs.pi-coding-agent = {
    enable = lib.mkEnableOption "pi-coding-agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pi-init;
      description = "Wrapper package that installs and runs pi-coding-agent.";
    };

    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to multi-line .env file with API keys such as ANTHROPIC_API_KEY.";
    };

    gitUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/suderman/pi";
      description = "Git repository cloned into ~/.pi for global pi-coding-agent configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    toolchains.javascript.enable = true;

    persist.storage.directories = [cfgDir];
    persist.scratch.directories = [".local/state/pi-coding-agent"];

    home.file.".local/bin/pi".source = "${cfg.package}/bin/pi";

    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      pi-coding-agent-env.rekeyFile = cfg.apiKeys;
    };

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
