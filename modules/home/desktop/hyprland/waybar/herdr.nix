{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.waybar.herdr;
  qsCfg = config.wayland.windowManager.hyprland.quickshell;
  colors = config.lib.stylix.colors;
  herdrPackage = config.programs.herdr.package;
  herdr =
    if herdrPackage == null
    then "herdr"
    else lib.getExe herdrPackage;
  inherit (lib) mkIf mkMerge mkOption types;

  icon = "󰚩";

  bridge = pkgs.self.mkScript {
    name = "herdr-status-bridge";
    path = with pkgs; [coreutils jq];
    env = {
      HERDR_STATUS_HERDR = herdr;
      HERDR_STATUS_INTERVAL = toString cfg.interval;
    };
    text =
      # bash
      ''
        set -u
        umask 077

        state_file="''${XDG_RUNTIME_DIR:?}/herdr-status.json"

        publish() {
          local tmp
          tmp="$(mktemp "$state_file.XXXXXX")"
          cat >"$tmp"
          mv -f "$tmp" "$state_file"
        }

        error_state() {
          local message="$1"
          jq -cn \
            --arg message "$message" \
            '{
              ok: false,
              class: "offline",
              message: $message,
              generatedAt: (now | floor),
              generatedAtText: (now | localtime | strftime("%-I:%M:%S%P")),
              counts: {total: 0, blocked: 0, done: 0, working: 0, idle: 0, unknown: 0},
              agents: []
            }'
        }

        update() {
          local raw normalized

          if ! raw="$("$HERDR_STATUS_HERDR" api snapshot 2>&1)"; then
            error_state "$raw" | publish
            return
          fi

          if ! normalized="$(printf '%s\n' "$raw" | jq -c '
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
            ($snapshot.agents | map(
              . as $agent |
              ($agent.agent_status // "unknown") as $status |
              ($workspaces[$agent.workspace_id] // {}) as $workspace |
              ($tabs[$agent.tab_id] // {}) as $tab |
              (($agent.cwd // "") | split("/") | map(select(length > 0)) | last // "home") as $cwd_label |
              {
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
            ) | sort_by([.priority, (.workspace | ascii_downcase), (.tab | ascii_downcase), .paneId])) as $agents |
            ($agents | map(select(.status == "blocked")) | length) as $blocked |
            ($agents | map(select(.status == "done")) | length) as $done |
            ($agents | map(select(.status == "working")) | length) as $working |
            ($agents | map(select(.status == "idle")) | length) as $idle |
            ($agents | map(select(.status == "unknown")) | length) as $unknown |
            {
              ok: true,
              class: (
                if $blocked > 0 then "blocked"
                elif $done > 0 then "done"
                elif $working > 0 then "working"
                elif $unknown > 0 and $idle == 0 then "unknown"
                else "idle"
                end
              ),
              generatedAt: (now | floor),
              generatedAtText: (now | localtime | strftime("%-I:%M:%S%P")),
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
          ' 2>&1)"; then
            error_state "$normalized" | publish
            return
          fi

          printf '%s\n' "$normalized" | publish
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
              (.agents[:10][]? | marker(.status) + " " + .workspace + " / " + .tab + " · " + .agentLabel),
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
    path = with pkgs; [coreutils kitty];
    env.HERDR_STATUS_HERDR = herdr;
    text =
      # bash
      ''
        target="''${1:?Usage: herdr-agent-open PANE_ID}"
        "$HERDR_STATUS_HERDR" agent focus "$target" >/dev/null
        nohup kitty --class=HerdrAgent --title="Herdr agent" \
          "$HERDR_STATUS_HERDR" agent attach "$target" \
          >/dev/null 2>&1 &
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
      "@BASE00@"
      "@BASE01@"
      "@BASE02@"
      "@BASE03@"
      "@BASE04@"
      "@BASE05@"
      "@BASE06@"
      "@BASE07@"
      "@BASE08@"
      "@BASE09@"
      "@BASE0A@"
      "@BASE0B@"
      "@BASE0D@"
    ]
    [
      (lib.getExe readState)
      (lib.getExe jump)
      icon
      (toString (cfg.interval * 1000))
      "#${colors.base00}"
      "#${colors.base01}"
      "#${colors.base02}"
      "#${colors.base03}"
      "#${colors.base04}"
      "#${colors.base05}"
      "#${colors.base06}"
      "#${colors.base07}"
      "#${colors.base08}"
      "#${colors.base09}"
      "#${colors.base0A}"
      "#${colors.base0B}"
      "#${colors.base0D}"
    ]
    (builtins.readFile ./herdr.qml));

  popupToggle = pkgs.self.mkScript {
    name = "herdr-popup";
    path = [qsCfg.package pkgs.systemd];
    text =
      # bash
      ''
        action="''${1:-toggle}"

        call() {
          qs ipc -c ${lib.escapeShellArg qsCfg.configName} call herdr "$@"
        }

        case "$action" in
          toggle | show | hide | refresh)
            if call "$action" >/dev/null 2>&1; then
              exit 0
            fi

            systemctl --user start quickshell.service >/dev/null 2>&1 || true

            for _ in {1..10}; do
              sleep 0.2
              if call "$action" >/dev/null 2>&1; then
                exit 0
              fi
            done

            echo "herdr-popup: quickshell IPC target unavailable" >&2
            exit 1
            ;;
          *)
            echo "Usage: herdr-popup [toggle|show|hide|refresh]" >&2
            exit 2
            ;;
        esac
      '';
  };
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
          then "${lib.getExe popupToggle} toggle"
          else lib.getExe openHerdr;
        on-click-right = lib.getExe openHerdr;
      };
    }

    (mkIf cfg.popup.enable {
      home.packages = [popupToggle];

      wayland.windowManager.hyprland.quickshell = {
        enable = true;
        components = [''Herdr {}''];
        files."Herdr.qml" = popupQml;
      };
    })
  ]);
}
