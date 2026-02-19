{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.botSupervisor;

  supervisor = pkgs.writeShellApplication {
    name = "bot-supervisor";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      findutils
      gawk
      gnugrep
      systemd
      util-linux
      procps
      iproute2
    ];
    text = ''
      set -euo pipefail

      APPS_DIR="${config.home.homeDirectory}/${cfg.appsDir}"
      mkdir -p "$APPS_DIR"

      log() { echo "[bot-supervisor] $*"; }

      # app file format: ~/.config/bot-apps/<name>.env
      #   ENABLED=1
      #   NAME=ops-live                (optional; defaults to filename)
      #   WORKDIR=/some/path           (optional)
      #   CMD=/some/command            (required)
      #   ARGS=...                     (optional; appended as-is)
      #   PORT=21340                   (optional; used for collision check)
      #   HOST=127.0.0.1               (optional; default 127.0.0.1)
      #   ENV_FOO=bar                  (optional env vars; prefix ENV_)
      #
      # Note: for quoting/complex args, prefer putting a wrapper script in WORKDIR and set CMD to it.

      is_listening() {
        local host="$1" port="$2"
        ss -ltnH "( sport = :$port )" 2>/dev/null | grep -q "$host:$port"
      }

      unit_for() { echo "bot-app-$1"; }

      start_or_update_app() {
        local f="$1"
        # shellcheck disable=SC1090
        source "$f"

        local enabled="''${ENABLED:-1}"
        local name="''${NAME:-$(basename "$f" .env)}"
        local workdir="''${WORKDIR:-}"
        local cmd="''${CMD:-}"
        local args="''${ARGS:-}"
        local host="''${HOST:-127.0.0.1}"
        local port="''${PORT:-}"

        if [[ "$enabled" != "1" ]]; then
          log "skip $name (disabled)"
          return 0
        fi

        if [[ -z "$cmd" ]]; then
          log "warn $name missing CMD in $f"
          return 0
        fi

        local unit; unit="$(unit_for "$name")"

        # If already active, do nothing (prevents flapping).
        if systemctl --user -q is-active "$unit" 2>/dev/null; then
          log "ok $name already active ($unit)"
          return 0
        fi

        # Optional port collision check (only if PORT is set)
        if [[ -n "$port" ]]; then
          if is_listening "$host" "$port"; then
            log "err $name cannot start: $host:$port already in use"
            return 1
          fi
        fi

        # Build environment args from ENV_* keys found in file.
        # We *only* pass ENV_* to the unit environment, not every variable.
        env_args=()
        while IFS='=' read -r k v; do
          [[ "$k" == ENV_* ]] || continue
          env_args+=( "--setenv" "''${k#ENV_}=$v" )
        done < <(grep -E '^(ENV_[A-Za-z0-9_]+)=' "$f" || true)

        # If unit already exists (loaded), prefer systemctl restart.
        if systemctl --user -q cat "$unit" >/dev/null 2>&1; then
          log "restart $name via systemctl ($unit)"
          systemctl --user reset-failed "$unit" 2>/dev/null || true
          systemctl --user restart "$unit"
          return 0
        fi

        log "start $name via systemd-run ($unit)"

        run_args=(
          systemd-run
          --user
          --unit "$unit"
          --collect
          --property "Restart=always"
          --property "RestartSec=1s"
          --property "KillSignal=SIGTERM"
          --property "TimeoutStopSec=5s"
        )

        if [[ -n "$workdir" ]]; then
          run_args+=( --working-directory "$workdir" )
        fi

        run_args+=( "''${env_args[@]}" )

        # Command + args:
        # We pass as: cmd then split args by shell (so keep ARGS simple).
        # If you need heavy quoting, wrap it in a script and set CMD to it.
        # shellcheck disable=SC2206
        cmdline=( "$cmd" )
        if [[ -n "$args" ]]; then
          # Split on whitespace intentionally
          # shellcheck disable=SC2206
          cmdline+=( $args )
        fi

        "''${run_args[@]}" "''${cmdline[@]}" >/dev/null
      }

      stop_removed_apps() {
        # Any active bot-app-* unit that no longer has a corresponding .env should be stopped.
        local active
        active="$(
          systemctl --user --plain --no-legend --no-pager list-units 'bot-app-*' 2>/dev/null \
            | awk '{print $1}' || true
        )"

        while IFS= read -r unit; do
          [[ -n "$unit" ]] || continue
          local name="''${unit#bot-app-}"
          name="''${name%.service}"

          if [[ ! -f "$APPS_DIR/$name.env" ]]; then
            log "stop removed $name ($unit)"
            systemctl --user stop "$unit" || true
          fi
        done <<< "$active"
      }

      reconcile_once() {
        log "reconcile (apps dir: $APPS_DIR)"
        shopt -s nullglob
        for f in "$APPS_DIR"/*.env; do
          start_or_update_app "$f" || true
        done
        stop_removed_apps || true
      }

      case "''${1:-run}" in
        run)
          while true; do
            reconcile_once
            sleep ${toString cfg.pollSeconds}
          done
          ;;
        once)
          reconcile_once
          ;;
        *)
          echo "usage: bot-supervisor {run|once}"
          exit 2
          ;;
      esac
    '';
  };
in {
  options.services.botSupervisor = {
    enable = lib.mkEnableOption "Bot app supervisor (transient systemd-run apps from ~/.config/bot-apps)";

    appsDir = lib.mkOption {
      type = lib.types.str;
      default = ".config/bot-apps";
      description = "Persisted directory of app definitions (*.env).";
    };

    pollSeconds = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "How often to reconcile app definitions.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [supervisor];

    # Your persistence module (if present) can pick this up:
    persist.storage.directories = [cfg.appsDir];

    systemd.user.services.bot-supervisor = {
      Unit = {
        Description = "Bot supervisor (imperative apps in ~/.config/bot-apps, launched via systemd-run)";
        After = ["default.target"];
      };

      Service = {
        ExecStart = "${supervisor}/bin/bot-supervisor run";
        ExecReload = "${supervisor}/bin/bot-supervisor once";
        Restart = "always";
        RestartSec = "1s";
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
