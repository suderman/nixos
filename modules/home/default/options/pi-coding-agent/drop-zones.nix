{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.pi-coding-agent;
  taskDropRoot = "${config.home.homeDirectory}/${config.home.directories.DOWNLOAD.path}";
  taskDropArchive = "${taskDropRoot}/.pi-tasks";
  taskDropPromptRoot = "${config.home.homeDirectory}/.agents/pi/task-drop-prompts";
  herdrPackage = config.programs.herdr.package;

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
  options.programs.pi-coding-agent.taskDropZones.enable = lib.mkEnableOption "trusted TODO and PROG prompt drop zones in the XDG downloads directory";

  config = lib.mkIf cfg.enable {
    assertions = lib.optional cfg.taskDropZones.enable {
      assertion = config.programs.herdr.enable && herdrPackage != null;
      message = "programs.pi-coding-agent.taskDropZones requires programs.herdr with a package";
    };

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
  };
}
