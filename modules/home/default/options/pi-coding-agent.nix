# programs.pi-coding-agent.enable = true;
{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.pi-coding-agent;

  agentDir = ".pi/agent";
  lensConfig = ".config/pi/pi-lens.json";
  stateDir = ".local/state/pi";
  taskDropRoot = "${config.home.homeDirectory}/${config.home.directories.DOWNLOAD.path}";
  taskDropArchive = "${taskDropRoot}/.pi-tasks";
  taskDropPromptRoot = "${config.home.homeDirectory}/.agents/pi/task-drop-prompts";
  herdrPackage = config.programs.herdr.package;

  # Pi owns one writable home. This wrapper only loads machine-provided secrets
  # and keeps supported third-party state overrides in their persistence roots.
  pi-init = pkgs.self.mkScript {
    name = "pi";
    path = [pkgs.systemd];
    text =
      # bash
      ''
        PI_BIN="''${PI_BIN:-${perSystem.agents.pi}/bin/pi}"
        PI_DIR="''${PI_DIR:-''${PI_CODING_AGENT_DIR:-${config.home.homeDirectory}/${agentDir}}}"
        PI_STATE_DIR="''${PI_STATE_DIR:-${config.home.homeDirectory}/${stateDir}}"

        export PI_CODING_AGENT_DIR="$PI_DIR"
        if [[ -z "''${PI_CODING_AGENT_SESSION_DIR:-}" ]]; then
          session_key="$(pwd -P)"
          session_key="''${session_key#/}"
          session_key="''${session_key//[\/\\:]/-}"
          export PI_CODING_AGENT_SESSION_DIR="$PI_STATE_DIR/sessions/--$session_key--"
        fi

        if systemctl --user --quiet is-enabled pi-coding-agent-env.service 2>/dev/null; then
          systemctl --user restart pi-coding-agent-env.service || true
        fi

        set -a
        [[ -f "$PI_DIR/.env" ]] && . "$PI_DIR/.env"
        [[ -f "$PI_DIR/.env.local" ]] && . "$PI_DIR/.env.local"
        set +a

        export PI_LENS_CONFIG_PATH="''${PI_LENS_CONFIG_PATH:-${config.home.homeDirectory}/${lensConfig}}"
        export PI_LENS_HOME="''${PI_LENS_HOME:-$PI_STATE_DIR/pi-lens}"
        export PILENS_DATA_DIR="''${PILENS_DATA_DIR:-$PI_LENS_HOME/projects}"
        export FFF_FRECENCY_DB="''${FFF_FRECENCY_DB:-$PI_STATE_DIR/fff/frecency}"
        export FFF_HISTORY_DB="''${FFF_HISTORY_DB:-$PI_STATE_DIR/fff/history}"

        exec "$PI_BIN" "$@"
      '';
  };

  taskDropHandler = pkgs.writeShellApplication {
    name = "pi-task-drop";
    runtimeInputs =
      (with pkgs; [coreutils findutils gnugrep jq util-linux])
      ++ lib.optional (herdrPackage != null) herdrPackage;
    text = ''
      mode="''${1:-}"
      case "$mode" in
        TODO|PROG) ;;
        *)
          echo "Usage: pi-task-drop TODO|PROG" >&2
          exit 2
          ;;
      esac

      prompt_file=${lib.escapeShellArg taskDropPromptRoot}/"$mode.org"
      if [[ ! -s "$prompt_file" ]]; then
        echo "Missing task-drop prompt: $prompt_file" >&2
        exit 1
      fi
      prompt="$(<"$prompt_file")"

      drop_dir=${lib.escapeShellArg taskDropRoot}/"$mode"
      archive_root=${lib.escapeShellArg taskDropArchive}
      result=0
      sequence=0
      mkdir -p "$drop_dir" "$archive_root/done/$mode" "$archive_root/failed/$mode"

      exec 9>"''${XDG_RUNTIME_DIR:?}/pi-task-drop.lock"
      flock 9

      archive_entry() {
        local source="$1"
        local bucket="$2"
        local basename="$3"

        mv --backup=numbered -- "$source" "$archive_root/$bucket/$mode/$basename"
      }

      run_task() {
        local entry="$1"
        local basename="$2"
        local session_name agent_name created pane_id attachment

        session_name="$(printf 'Inbox %s: %s' "$mode" "$basename" | tr '\r\n' ' ' | cut -c1-80)"
        sequence=$((sequence + 1))
        agent_name="inbox-''${mode,,}-$$-$sequence"

        created="$(herdr --session default workspace create \
          --cwd ${lib.escapeShellArg "${config.home.homeDirectory}/org"} \
          --label "$session_name" --no-focus)" || return
        pane_id="$(printf '%s\n' "$created" | jq -er '.result.root_pane.pane_id')" || return

        herdr --session default agent start "$agent_name" \
          --kind pi --pane "$pane_id" -- --no-approve --name "$session_name" || return

        attachment="$(mktemp --suffix=.txt "''${XDG_RUNTIME_DIR:?}/pi-task-drop.XXXXXX")" || return
        if ! cp -- "$entry" "$attachment"; then
          rm -f -- "$attachment"
          return 1
        fi

        if herdr --session default agent prompt "$agent_name" \
          "$prompt"$'\n\n'"@$attachment" \
          --wait --until idle --until "done"; then
          rm -f -- "$attachment"
          return 0
        fi

        rm -f -- "$attachment"
        return 1
      }

      while IFS= read -r -d "" entry; do
        basename="''${entry##*/}"

        if [[ -L "$entry" || ! -f "$entry" ]]; then
          echo "Rejecting non-regular drop-zone entry: $entry" >&2
          archive_entry "$entry" failed "$basename"
          result=1
          continue
        fi

        before="$(stat -c '%s:%Y' -- "$entry")"
        sleep 2
        [[ -e "$entry" ]] || continue
        after="$(stat -c '%s:%Y' -- "$entry")"
        [[ "$before" == "$after" ]] || continue

        size="''${after%%:*}"
        if ((size > 1048576)); then
          echo "Rejecting drop-zone file larger than 1 MiB: $entry" >&2
          archive_entry "$entry" failed "$basename"
          result=1
          continue
        fi
        if ! grep -Iq . -- "$entry"; then
          echo "Rejecting empty or non-text drop-zone file: $entry" >&2
          archive_entry "$entry" failed "$basename"
          result=1
          continue
        fi

        echo "Processing $mode task through Herdr: $entry"
        if run_task "$entry" "$basename"; then
          archive_entry "$entry" "done" "$basename"
        else
          archive_entry "$entry" failed "$basename"
          result=1
        fi
      done < <(find "$drop_dir" -mindepth 1 -maxdepth 1 -print0)

      exit "$result"
    '';
  };
in {
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

    taskDropZones.enable = lib.mkEnableOption "trusted TODO and PROG prompt drop zones in the XDG downloads directory";
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.optional cfg.taskDropZones.enable {
      assertion = config.programs.herdr.enable && herdrPackage != null;
      message = "programs.pi-coding-agent.taskDropZones requires programs.herdr with a package";
    };

    toolchains.javascript.enable = true;

    # Keep user-managed Lens config durable. Pi runtime data is scratch-persisted.
    persist.storage.directories = [".config/pi"];
    persist.scratch.directories = [agentDir stateDir];

    # Put the wrapper at the conventional user-bin path without exposing the
    # implementation package name to callers.
    home.file.".local/bin/pi".source = "${cfg.package}/bin/pi";

    home.activation.piAgentConfiguration = lib.hm.dag.entryAfter ["agentConfigurationCheckout"] ''
      $DRY_RUN_CMD env \
        PATH=${lib.makeBinPath [pkgs.bash pkgs.coreutils pkgs.jq]}:$PATH \
        PI_CODING_AGENT_DIR=${config.home.homeDirectory}/${agentDir} \
        XDG_STATE_HOME=${config.home.homeDirectory}/.local/state \
        ${config.home.homeDirectory}/.agents/pi/bootstrap
    '';

    home.activation.piHerdrIntegration = lib.mkIf (config.programs.herdr.enable && herdrPackage != null) (
      lib.hm.dag.entryAfter ["piAgentConfiguration"] ''
        $DRY_RUN_CMD env \
          PI_CODING_AGENT_DIR=${config.home.homeDirectory}/${agentDir} \
          ${lib.getExe herdrPackage} integration install pi
      ''
    );

    tmpfiles.directories = lib.optionals cfg.taskDropZones.enable [
      {
        target = "${config.home.directories.DOWNLOAD.path}/TODO";
        mode = "0700";
      }
      {
        target = "${config.home.directories.DOWNLOAD.path}/PROG";
        mode = "0700";
      }
    ];

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

    systemd.user.services.pi-task-drop-todo = lib.mkIf cfg.taskDropZones.enable {
      Unit.Description = "Run Pi TODO drop-zone tasks through Herdr";
      Service = {
        Type = "oneshot";
        WorkingDirectory = "${config.home.homeDirectory}/org";
        TimeoutStartSec = "infinity";
        ExecStart = "${lib.getExe taskDropHandler} TODO";
      };
    };

    systemd.user.services.pi-task-drop-prog = lib.mkIf cfg.taskDropZones.enable {
      Unit.Description = "Run Pi PROG drop-zone tasks through Herdr";
      Service = {
        Type = "oneshot";
        WorkingDirectory = "${config.home.homeDirectory}/org";
        TimeoutStartSec = "infinity";
        ExecStart = "${lib.getExe taskDropHandler} PROG";
      };
    };

    systemd.user.paths.pi-task-drop-todo = lib.mkIf cfg.taskDropZones.enable {
      Unit.Description = "Watch Pi TODO drop zone";
      Path = {
        DirectoryNotEmpty = "${taskDropRoot}/TODO";
        Unit = "pi-task-drop-todo.service";
      };
      Install.WantedBy = ["default.target"];
    };

    systemd.user.paths.pi-task-drop-prog = lib.mkIf cfg.taskDropZones.enable {
      Unit.Description = "Watch Pi PROG drop zone";
      Path = {
        DirectoryNotEmpty = "${taskDropRoot}/PROG";
        Unit = "pi-task-drop-prog.service";
      };
      Install.WantedBy = ["default.target"];
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
