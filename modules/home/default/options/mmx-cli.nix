{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.mmx-cli;
  cfgDir = ".mmx";

  mmx-init = pkgs.self.mkScript {
    name = "mmx";
    path = [pkgs.nodejs];
    text = ''
      MMX_BIN="''${MMX_BIN:-${config.home.sessionVariables.NPM_CONFIG_PREFIX}/bin/mmx}"
      MMX_DIR="''${MMX_DIR:-${config.home.homeDirectory}/${cfgDir}}"
      MMX_INIT_STAMP="''${MMX_INIT_STAMP:-${config.home.homeDirectory}/${cfgDir}/init.timestamp}"
      MMX_INIT_INTERVAL="$((24 * 60 * 60))"

      mmx_init() {
        mkdir -p "$MMX_DIR"
        npm i -g mmx-cli

        if [[ ! -f "$MMX_BIN" ]]; then
          echo "Failed to install mmx binary" >&2
          exit 1
        fi

        mkdir -p "$(dirname "$MMX_INIT_STAMP")"
        date +%s >"$MMX_INIT_STAMP"
      }

      mmx_init_stale() {
        [[ ! -f "$MMX_INIT_STAMP" ]] && return 0

        local now last
        now="$(date +%s)"
        last="$(<"$MMX_INIT_STAMP")"

        [[ ! "$last" =~ ^[0-9]+$ ]] && return 0
        ((now - last >= MMX_INIT_INTERVAL))
      }

      if [[ "''${1:-}" == "init" ]]; then
        mmx_init
      elif [[ ! -f "$MMX_DIR/config.json" ]] || [[ ! -e "$MMX_BIN" ]] || mmx_init_stale; then
        mmx_init
        "$MMX_BIN" "$@"
      else
        "$MMX_BIN" "$@"
      fi
    '';
  };
in {
  options.programs.mmx-cli = let
    filler = lib.mkOption {
      type = lib.types.anything;
      default = {};
    };
  in {
    settings = filler;

    enable = lib.mkEnableOption "mmx-cli";

    package = lib.mkOption {
      type = lib.types.package;
      default = mmx-init;
    };

    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to multi-line .env file with MINIMAX_API_KEY=123";
    };
  };

  config = lib.mkIf cfg.enable {
    toolchains.javascript.enable = true;

    persist.storage.directories = [cfgDir];

    home.file.".local/bin/mmx".source = "${cfg.package}/bin/mmx";

    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      mmx-cli-env.rekeyFile = cfg.apiKeys;
    };

    home.activation.mmx-cli = let
      keysEnv =
        if cfg.apiKeys != null
        then config.age.secrets.mmx-cli-env.path
        else "/dev/null";
    in
      lib.hm.dag.entryAfter ["writeBoundary"]
      # sh
      ''
        MMX_DIR="$HOME/${cfgDir}"
        mkdir -p "$MMX_DIR"

        set -a
        [[ -f "${keysEnv}" ]] && . "${keysEnv}"
        set +a

        if [[ -n "''${MINIMAX_API_KEY-}" ]]; then
          printf '{"region":"global","api_key":"%s"}\n' "$MINIMAX_API_KEY" > "$MMX_DIR/config.json"
          chmod 600 "$MMX_DIR/config.json"
        fi
      '';

    programs.zsh.initContent =
      lib.mkAfter
      # sh
      ''
        cli() {
          [[ -z "''${*}" ]] && return 1

          local system_prompt out cmd

          system_prompt=$(cat <<EOF
        You are a CLI assistant running on NixOS.

        Only output shell-related text.
        Reasoning is allowed, but the final line must be a single valid shell command.

        Environment:
        - Time: $(date)
        - Working directory: $(pwd)
        - Shell: $(ps -p $$ -o comm=)

        Useful inspection commands:
        - command -v <cmd>
        - type -a <cmd>
        - man -k <keyword>

        Rules:
        - Prefer standard Unix tools available on NixOS.
        - If unsure whether a command exists, check with: command -v <cmd>
        - Prefer portable commands unless a better installed tool is clearly appropriate.
        - Use absolute or explicit paths when needed.
        - Avoid interactive commands unless explicitly requested.
        - Quote paths and arguments safely.
        - Prefer simple, readable pipelines.
        - Prefer idempotent commands when possible.
        - Final line must be valid shell command.
        - No markdown! No code blocks! No backticks!

        EOF
        )

          mmx text chat --non-interactive --quiet --system "$system_prompt" --message "$*"

          if [[ -n "$KITTY_WINDOW_ID" ]] && kitty @ ls >/dev/null 2>&1; then
            kitty @ get-text --extent all | awk 'NF{line=$0} END{printf "%s", line}' | wl-copy
          fi
        }
      '';
  };
}
