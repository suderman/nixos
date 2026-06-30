# programs.pi-coding-agent.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.pi-coding-agent;

  # Upstream pi expects to own one mutable directory. Keep that path as a
  # disposable facade and link durable files back to the repo's normal persisted
  # config/state roots below.
  agentDir = ".pi/agent";
  configDir = ".config/pi";
  stateDir = ".local/state/pi";

  # The real pi package is installed imperatively into the user's npm prefix.
  # This wrapper makes that install lazy and recreates the expected directory
  # layout before every invocation.
  pi-init = pkgs.self.mkScript {
    name = "pi";
    path = [pkgs.nodejs pkgs.systemd];
    text =
      # bash
      ''
        export NPM_CONFIG_PREFIX="${config.home.sessionVariables.NPM_CONFIG_PREFIX}"
        export NPM_CONFIG_CACHE="${config.home.sessionVariables.NPM_CONFIG_CACHE}"

        PI_BIN="''${PI_BIN:-${config.home.sessionVariables.NPM_CONFIG_PREFIX}/bin/pi}"
        PI_CONFIG_DIR="''${PI_CONFIG_DIR:-${config.home.homeDirectory}/${configDir}}"
        PI_STATE_DIR="''${PI_STATE_DIR:-${config.home.homeDirectory}/${stateDir}}"
        PI_DIR="''${PI_DIR:-''${PI_CODING_AGENT_DIR:-${config.home.homeDirectory}/${agentDir}}}"

        export PI_CODING_AGENT_DIR="$PI_DIR"

        pi_safe_dir() {
          local label="$1"
          local dir="$2"

          if [[ -z "$dir" || "$dir" == "/" || "$dir" == "${config.home.homeDirectory}" ]]; then
            echo "Refusing to manage unsafe pi-coding-agent $label directory: $dir" >&2
            exit 1
          fi
        }

        pi_json_file() {
          local target="$1"
          local mode="''${2:-0644}"

          mkdir -p "$(dirname "$target")"
          if [[ ! -e "$target" ]]; then
            printf '{}\n' >"$target"
            chmod "$mode" "$target"
          fi
        }

        pi_file() {
          local target="$1"
          local mode="''${2:-0644}"

          mkdir -p "$(dirname "$target")"
          if [[ ! -e "$target" ]]; then
            : >"$target"
            chmod "$mode" "$target"
          fi
        }

        pi_dir() {
          mkdir -p "$1"
        }

        pi_link() {
          local source="$1"
          local target="$2"

          mkdir -p "$(dirname "$target")"
          rm -rf "$target"
          ln -s "$source" "$target"
        }

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

        pi_agent_init() {
          # These guards keep a bad override from deleting or symlinking over
          # $HOME, /, or one of the persistence roots.
          pi_safe_dir "config" "$PI_CONFIG_DIR"
          pi_safe_dir "state" "$PI_STATE_DIR"
          pi_safe_dir "agent" "$PI_DIR"

          if [[ "$PI_DIR" == "$PI_CONFIG_DIR" || "$PI_DIR" == "$PI_STATE_DIR" ]]; then
            echo "Refusing to use pi-coding-agent facade directory as a persistence root: $PI_DIR" >&2
            exit 1
          fi

          mkdir -p "$PI_CONFIG_DIR" "$PI_STATE_DIR" "$PI_DIR"

          # User-editable configuration is persisted across rebuilds and hosts.
          pi_file "$PI_CONFIG_DIR/AGENTS.md"
          pi_json_file "$PI_CONFIG_DIR/models.json"
          pi_json_file "$PI_CONFIG_DIR/keybindings.json"
          pi_json_file "$PI_CONFIG_DIR/settings.json"
          pi_json_file "$PI_CONFIG_DIR/settings-extensions.json"
          pi_json_file "$PI_CONFIG_DIR/mcp.json"
          pi_dir "$PI_CONFIG_DIR/extensions"
          pi_dir "$PI_CONFIG_DIR/prompts"
          pi_dir "$PI_CONFIG_DIR/themes"
          pi_dir "$PI_CONFIG_DIR/skills"

          # Auth, trust decisions, sessions, and npm/git scratch data are state:
          # keep them out of the config backup path, but survive one CLI run to
          # the next on machines with scratch persistence enabled.
          pi_json_file "$PI_STATE_DIR/auth.json" 0600
          pi_json_file "$PI_STATE_DIR/mcp-onboarding.json" 0600
          pi_json_file "$PI_STATE_DIR/trust.json" 0600
          pi_dir "$PI_STATE_DIR/sessions"
          pi_dir "$PI_STATE_DIR/npm"
          pi_dir "$PI_STATE_DIR/git"

          # Rebuild the facade unconditionally so upstream can keep using its
          # flat directory layout while Home Manager controls where data lives.
          pi_link "$PI_CONFIG_DIR/AGENTS.md" "$PI_DIR/AGENTS.md"
          pi_link "$PI_CONFIG_DIR/models.json" "$PI_DIR/models.json"
          pi_link "$PI_CONFIG_DIR/keybindings.json" "$PI_DIR/keybindings.json"
          pi_link "$PI_CONFIG_DIR/settings.json" "$PI_DIR/settings.json"
          pi_link "$PI_CONFIG_DIR/settings-extensions.json" "$PI_DIR/settings-extensions.json"
          pi_link "$PI_CONFIG_DIR/mcp.json" "$PI_DIR/mcp.json"
          pi_link "$PI_CONFIG_DIR/extensions" "$PI_DIR/extensions"
          pi_link "$PI_CONFIG_DIR/prompts" "$PI_DIR/prompts"
          pi_link "$PI_CONFIG_DIR/themes" "$PI_DIR/themes"
          pi_link "$PI_CONFIG_DIR/skills" "$PI_DIR/skills"

          pi_link "$PI_STATE_DIR/auth.json" "$PI_DIR/auth.json"
          pi_link "$PI_STATE_DIR/mcp-onboarding.json" "$PI_DIR/mcp-onboarding.json"
          pi_link "$PI_STATE_DIR/trust.json" "$PI_DIR/trust.json"
          pi_link "$PI_STATE_DIR/sessions" "$PI_DIR/sessions"
          pi_link "$PI_STATE_DIR/npm" "$PI_DIR/npm"
          pi_link "$PI_STATE_DIR/git" "$PI_DIR/git"
        }

        pi_init() {
          pi_agent_init

          # pi is not packaged in nixpkgs here, so install the published npm CLI
          # into the Home Manager-managed npm prefix on first use.
          npm i -g --ignore-scripts @earendil-works/pi-coding-agent

          if [[ ! -f "$PI_BIN" ]]; then
            echo "Failed to install pi binary" >&2
            exit 1
          fi
        }

        if [[ "''${1:-}" == "init" ]]; then
          pi_init
          pi_env_init
          exit 0
        fi

        pi_agent_init

        if [[ ! -e "$PI_BIN" ]]; then
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
  };

  config = lib.mkIf cfg.enable {
    toolchains.javascript.enable = true;

    # Config is durable; runtime auth/session/cache data is only scratch-persisted.
    persist.storage.directories = [configDir];
    persist.scratch.directories = [stateDir];

    # Put the wrapper at the conventional user-bin path without exposing the
    # implementation package name to callers.
    home.file.".local/bin/pi".source = "${cfg.package}/bin/pi";

    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      pi-coding-agent-env.rekeyFile = cfg.apiKeys;
    };

    # pi commonly enters its own agent directory; allow direnv there without
    # broadening the whitelist to the rest of $HOME.
    programs.direnv.config.whitelist.prefix = [
      "${config.home.homeDirectory}/${agentDir}"
    ];

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
