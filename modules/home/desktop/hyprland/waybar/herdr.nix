{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.waybar.herdr;
  herdrPackage = config.programs.herdr.package;
  herdr =
    if herdrPackage == null
    then "herdr"
    else lib.getExe herdrPackage;
  inherit (lib) mkIf mkMerge mkOption types;

  icon = "󰚩";

  # This host first, then the other workers.
  self = config.networking.hostName;
  hosts = [self] ++ lib.remove self config.programs.herdr.workers;

  bridge = pkgs.self.mkScript {
    name = "herdr-status-bridge";
    path = with pkgs; [coreutils jq openssh];
    env = {
      HERDR_STATUS_HERDR = herdr;
      HERDR_STATUS_INTERVAL = toString cfg.interval;
      HERDR_STATUS_HOSTS = toString hosts;
    };
    text =
      # bash
      ''
        set -u
        umask 077

        state_file="''${XDG_RUNTIME_DIR:?}/herdr-status.json"
        read -ra hosts <<<"$HERDR_STATUS_HOSTS"

        publish() {
          local tmp
          tmp="$(mktemp "$state_file.XXXXXX")"
          cat >"$tmp"
          mv -f "$tmp" "$state_file"
        }

        # One host's result: {host, ok, message} or {host, ok, agents}.
        host_error() {
          jq -cn --arg host "$1" --arg message "$2" '{host: $host, ok: false, message: $message}'
        }

        # Short reasons for the usual SSH failures; anything else keeps its first line.
        ssh_reason() {
          case "$1" in
          *"Permission denied"*) echo "SSH key locked" ;;
          *"timed out"* | *"No route"* | *"Could not resolve"* | *"Connection refused"* | *"Network is unreachable"*) echo "unreachable" ;;
          *"command not found"*) echo "herdr not installed" ;;
          *"herdr"*"socket"* | *"server"*"not running"*) echo "herdr server not running" ;;
          *) tr -d '\r' <<<"$1" | head -n 1 ;;
          esac
        }

        poll() {
          local host="$1" rank="$2" raw normalized

          if [[ $host == "''${hosts[0]}" ]]; then
            raw="$("$HERDR_STATUS_HERDR" api snapshot 2>&1)"
          else
            # Reuses the ControlMaster from ~/.ssh/config, so a warm poll is cheap.
            raw="$(timeout 10 ssh -o BatchMode=yes -o ConnectTimeout=3 "$host" herdr api snapshot 2>&1)"
          fi || {
            host_error "$host" "$(ssh_reason "$raw")"
            return
          }

          if ! normalized="$(printf '%s\n' "$raw" | jq -c --arg host "$host" --argjson rank "$rank" '
            def text($value; $fallback):
              if $value == null or ($value | tostring | length) == 0
              then $fallback
              else ($value | tostring)
              end;

            def priority($status):
              if $status == "blocked" then 0
              elif $status == "done" then 1
              elif $status == "working" then 2
              elif $status == "idle" then 3
              else 4
              end;

            .result.snapshot as $snapshot |
            ($snapshot.workspaces | map({key: .workspace_id, value: .}) | from_entries) as $workspaces |
            ($snapshot.tabs | map({key: .tab_id, value: .}) | from_entries) as $tabs |
            {
              host: $host,
              ok: true,
              agents: ($snapshot.agents | map(
                . as $agent |
                ($agent.agent_status // "unknown") as $status |
                ($workspaces[$agent.workspace_id] // {}) as $workspace |
                ($tabs[$agent.tab_id] // {}) as $tab |
                (($agent.cwd // "") | split("/") | map(select(length > 0)) | last // "home") as $cwd_label |
                {
                  host: $host,
                  hostRank: $rank,
                  paneId: ($agent.pane_id // ""),
                  terminalId: ($agent.terminal_id // ""),
                  workspaceId: ($agent.workspace_id // ""),
                  workspace: text($workspace.label; $cwd_label),
                  tabId: ($agent.tab_id // ""),
                  tab: text($tab.label; text($tab.number; "tab")),
                  agentLabel: text($agent.display_agent; text($agent.agent; "agent")),
                  status: $status,
                  statusLabel: text($agent.state_labels[$status]; $status),
                  title: text($agent.title; text($agent.terminal_title_stripped; "")),
                  cwd: ($agent.foreground_cwd // $agent.cwd // ""),
                  focused: ($agent.focused // false),
                  stateChangeSeq: ($agent.state_change_seq // 0),
                  priority: priority($status)
                }
              ))
            }
          ' 2>&1)"; then
            host_error "$host" "$normalized"
            return
          fi

          printf '%s\n' "$normalized"
        }

        update() {
          local dir rank
          dir="$(mktemp -d)"

          # Poll every host at once so an unreachable one costs its timeout, not a turn.
          for rank in "''${!hosts[@]}"; do
            poll "''${hosts[$rank]}" "$rank" >"$dir/$rank.json" &
          done
          wait

          jq -cs '
            (map(.agents // []) | add // []
              | sort_by([.hostRank, .priority, (.workspace | ascii_downcase), (.tab | ascii_downcase), .paneId])) as $agents |
            ($agents | map(select(.status == "blocked")) | length) as $blocked |
            ($agents | map(select(.status == "done")) | length) as $done |
            ($agents | map(select(.status == "working")) | length) as $working |
            ($agents | map(select(.status == "idle")) | length) as $idle |
            ($agents | map(select(.status == "unknown")) | length) as $unknown |
            {
              ok: any(.[]; .ok),
              message: (map(select(.ok | not) | .host + ": " + .message) | join("\n")),
              class: (
                if all(.[]; .ok | not) then "offline"
                elif $blocked > 0 then "blocked"
                elif $done > 0 then "done"
                elif $working > 0 then "working"
                elif $unknown > 0 and $idle == 0 then "unknown"
                else "idle"
                end
              ),
              generatedAt: (now | floor),
              generatedAtText: (now | localtime | strftime("%-I:%M:%S%P")),
              hosts: map({host, ok, message: (.message // ""), count: ((.agents // []) | length)}),
              counts: {
                total: ($agents | length),
                blocked: $blocked,
                done: $done,
                working: $working,
                idle: $idle,
                unknown: $unknown
              },
              agents: $agents
            }
          ' "$dir"/*.json | publish

          rm -rf "$dir"
        }

        update
        if [[ "''${1:-}" == "--once" ]]; then
          exit 0
        fi

        while sleep "$HERDR_STATUS_INTERVAL"; do
          update
        done
      '';
  };

  readState = pkgs.self.mkScript {
    name = "herdr-status-data";
    path = with pkgs; [coreutils jq];
    env.HERDR_STATUS_STALE_AFTER = toString (cfg.interval * 3 + 2);
    text =
      # bash
      ''
        state_file="''${XDG_RUNTIME_DIR:?}/herdr-status.json"

        if [[ ! -s "$state_file" ]]; then
          jq -cn '{
            ok: false,
            class: "offline",
            message: "Herdr status bridge has not produced state yet.",
            counts: {total: 0, blocked: 0, done: 0, working: 0, idle: 0, unknown: 0},
            agents: []
          }'
          exit 0
        fi

        jq -c \
          --argjson now "$(date +%s)" \
          --argjson stale_after "$HERDR_STATUS_STALE_AFTER" \
          'if .ok == true and ($now - (.generatedAt // 0)) > $stale_after
           then . + {ok: false, class: "offline", message: "Herdr status bridge state is stale."}
           else .
           end' \
          "$state_file"
      '';
  };

  waybar = pkgs.self.mkScript {
    name = "waybar-herdr";
    path = [pkgs.jq];
    env.HERDR_STATUS_ICON = icon;
    text =
      # bash
      ''
        if ! data="$(${lib.getExe readState})"; then
          data='{"ok":false,"class":"offline","message":"Failed to read Herdr state.","counts":{},"agents":[]}'
        fi

        printf '%s\n' "$data" | jq -c --arg icon "$HERDR_STATUS_ICON" '
          def marker($status):
            if $status == "blocked" then "!"
            elif $status == "done" then "✓"
            elif $status == "working" then "●"
            elif $status == "idle" then "○"
            else "?"
            end;

          (.counts // {}) as $counts |
          if .ok == true then
            ([
              $icon + (if ($counts.total // 0) > 0 then " " + (($counts.total // 0) | tostring) else "" end),
              if ($counts.blocked // 0) > 0 then "!" + ($counts.blocked | tostring) else empty end,
              if ($counts.done // 0) > 0 then "✓" + ($counts.done | tostring) else empty end,
              if ($counts.working // 0) > 0 then "●" + ($counts.working | tostring) else empty end,
              if ($counts.unknown // 0) > 0 and (($counts.blocked // 0) + ($counts.done // 0) + ($counts.working // 0)) == 0
              then "?" + ($counts.unknown | tostring)
              else empty
              end
            ] | join("  ")) as $text |
            ([
              "Herdr agents: " + (($counts.total // 0) | tostring),
              "blocked " + (($counts.blocked // 0) | tostring)
                + ", unseen done " + (($counts.done // 0) | tostring)
                + ", working " + (($counts.working // 0) | tostring)
                + ", idle " + (($counts.idle // 0) | tostring)
                + (if ($counts.unknown // 0) > 0 then ", unknown " + ($counts.unknown | tostring) else "" end),
              ((.hosts // []) as $hosts | if ($hosts | length) > 1 then
                ($hosts | map(.host + " " + (if .ok then (.count | tostring) else .message end)) | join(" · "))
              else empty end),
              (((.hosts // []) | length) > 1) as $many |
              (.agents[:10][]? | marker(.status) + " " + (if $many then .host + ": " else "" end) + .workspace + " / " + .tab + " · " + .agentLabel),
              if (.agents | length) > 10 then "… " + (((.agents | length) - 10) | tostring) + " more" else empty end
            ] | join("\n")) as $tooltip |
            {text: $text, tooltip: $tooltip, class: (.class // "idle")}
          else
            {
              text: ($icon + " ?"),
              tooltip: ("Herdr unavailable\n" + (.message // "No state available.")),
              class: "offline"
            }
          end
        '
      '';
  };

  jump = pkgs.self.mkScript {
    name = "herdr-agent-open";
    path = with pkgs; [coreutils jq kitty openssh];
    env = {
      HERDR_STATUS_HERDR = herdr;
      HERDR_STATUS_SELF = self;
    };
    text =
      # bash
      ''
        host="''${1:?Usage: herdr-agent-open HOST PANE_ID}"
        target="''${2:?Usage: herdr-agent-open HOST PANE_ID}"

        # Remote attach runs over SSH; Herdr does not forward interactive attach.
        if [[ $host == "$HERDR_STATUS_SELF" ]]; then
          attach=("$HERDR_STATUS_HERDR" agent attach "$target")
          "$HERDR_STATUS_HERDR" agent focus "$target" >/dev/null
        else
          attach=(ssh -t "$host" herdr agent attach "$target")
          ssh -o BatchMode=yes -o ConnectTimeout=3 "$host" herdr agent focus "$target" >/dev/null
        fi

        # Direct attach is exclusive. Reuse its Kitty instead of opening an
        # attachment that immediately exits. Pane IDs repeat across hosts, so
        # match the whole attach command.
        window="$(
          hyprctl -j clients | jq -r '
            .[]
            | select(.class == "HerdrAgent")
            | [.address, .workspace.name, (.pid | tostring)]
            | @tsv
          ' | while IFS=$'\t' read -r address workspace pid; do
            [[ -r "/proc/$pid/cmdline" ]] || continue
            mapfile -d "" args <"/proc/$pid/cmdline"
            if [[ " ''${args[*]} " == *" ''${attach[*]} "* ]]; then
              printf '%s\t%s\n' "$address" "$workspace"
              break
            fi
          done
        )"

        if [[ -n "$window" ]]; then
          IFS=$'\t' read -r address workspace <<<"$window"
          hyprctl dispatch "hl.dsp.focus({ workspace = \"$workspace\" })" >/dev/null
          hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
          exit 0
        fi

        nohup kitty --class=HerdrAgent --title="Herdr agent $host" "''${attach[@]}" >/dev/null 2>&1 &
      '';
  };

  openHerdr = pkgs.self.mkScript {
    name = "herdr-open";
    path = with pkgs; [coreutils kitty];
    env.HERDR_STATUS_HERDR = herdr;
    text =
      # bash
      ''
        nohup kitty --class=Herdr --title=Herdr "$HERDR_STATUS_HERDR" >/dev/null 2>&1 &
      '';
  };

  popupQml = pkgs.writeText "Herdr.qml" (builtins.replaceStrings
    [
      "@DATA_COMMAND@"
      "@JUMP_COMMAND@"
      "@ICON@"
      "@INTERVAL_MS@"
    ]
    [
      (lib.getExe readState)
      (lib.getExe jump)
      icon
      (toString (cfg.interval * 1000))
    ]
    (builtins.readFile ./herdr.qml));
in {
  options.wayland.windowManager.hyprland.waybar.herdr = {
    enable = lib.mkEnableOption "Herdr agent status Waybar widget";

    interval = mkOption {
      type = types.ints.positive;
      default = 5;
      description = "Herdr snapshot polling interval in seconds.";
    };

    popup.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the Quickshell Herdr agent roster on click.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = config.programs.herdr.enable && herdrPackage != null;
          message = "waybar.herdr requires programs.herdr with a package";
        }
      ];

      systemd.user.services.herdr-status = {
        Unit = {
          Description = "Herdr desktop status bridge";
          PartOf = [config.wayland.systemd.target];
          After = [config.wayland.systemd.target];
        };
        Service = {
          ExecStart = lib.getExe bridge;
          # Remote hosts need the same agent as June's SSH calls.
          Environment = ["SSH_AUTH_SOCK=%t/${config.programs.ssh.agentSocket}"];
          Restart = "always";
          RestartSec = 3;
        };
        Install.WantedBy = [config.wayland.systemd.target];
      };

      programs.waybar.settings.bar."custom/herdr" = {
        return-type = "json";
        exec = lib.getExe waybar;
        format = "{text}";
        max-length = 32;
        interval = cfg.interval;
        tooltip = true;
        on-click =
          if cfg.popup.enable
          then "${lib.getExe config.lib.quickshell.ipc} herdr toggle"
          else lib.getExe openHerdr;
        on-click-right = lib.getExe openHerdr;
      };

      # The agent window is kitty with its own class; give it kitty's shortcuts
      services.keyd.windows.HerdrAgent = config.services.keyd.windows.kitty;
    }

    (mkIf cfg.popup.enable {
      wayland.windowManager.hyprland.quickshell = {
        enable = true;
        components = [''Herdr {}''];
        files."Herdr.qml" = popupQml;
      };
    })
  ]);
}
