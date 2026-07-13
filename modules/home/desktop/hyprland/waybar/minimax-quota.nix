{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.waybar.minimax-quota;
  qsCfg = config.wayland.windowManager.hyprland.quickshell;
  colors = config.lib.stylix.colors;
  inherit (lib) mkIf mkMerge mkOption types;

  icon = "󱙺";

  quotaData = pkgs.self.mkScript {
    name = "minimax-quota-data";
    path = with pkgs; [jq nodejs];
    env = {
      MINIMAX_QUOTA_COMMAND = cfg.command;
      MINIMAX_QUOTA_MODEL = cfg.modelName;
    };
    text =
      # bash
      ''
        json_error() {
          local status="$1"
          local title="$2"
          local message="$3"

          jq -cn \
            --arg status "$status" \
            --arg title "$title" \
            --arg message "$message" \
            '{
              ok: false,
              class: "critical",
              status: $status,
              title: $title,
              message: $message,
              modelName: "",
              interval: {},
              weekly: {}
            }'
        }

        if [[ ! -x "$MINIMAX_QUOTA_COMMAND" ]]; then
          json_error \
            "missing" \
            "MiniMax CLI unavailable" \
            "MiniMax quota command is not executable: $MINIMAX_QUOTA_COMMAND"
          exit 0
        fi

        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT

        quota="$tmp/quota.json"
        err="$tmp/quota.err"

        if "$MINIMAX_QUOTA_COMMAND" quota --non-interactive --quiet --output json >"$quota" 2>"$err"; then
          :
        else
          code=$?
          message="Failed to run mmx quota --output json (exit $code)."
          if [[ -s "$err" ]]; then
            message="$(printf '%s\n%s' "$message" "$(<"$err")")"
          fi

          json_error \
            "command" \
            "MiniMax quota failed" \
            "$message"
          exit 0
        fi

        if ! output="$(jq -cn \
          --slurpfile quota "$quota" \
          --arg model "$MINIMAX_QUOTA_MODEL" \
          '
          def number($n): $n | tonumber? // null;

          def num_text($n):
            (number($n)) as $v |
            if $v == null then "n/a"
            else
              (($v * 10 | round) / 10 | tostring) as $s |
              if ($s | endswith(".0")) then $s[0:-2] else $s end
            end;

          def pct_text($n):
            (number($n)) as $v |
            if $v == null then "n/a" else num_text($v) + "%" end;

          def duration_text($ms):
            (number($ms)) as $v |
            if $v == null then "n/a"
            else
              ((if $v < 0 then 0 else $v end) / 1000 | floor) as $seconds |
              ($seconds / 86400 | floor) as $days |
              (($seconds % 86400) / 3600 | floor) as $hours |
              (($seconds % 3600) / 60 | floor) as $minutes |
              if $days > 0 then "\($days)d \($hours)h"
              elif $hours > 0 then "\($hours)h \($minutes)m"
              else "\($minutes)m"
              end
            end;

          def time_text($ms):
            (number($ms)) as $v |
            if $v == null or $v <= 0 then "n/a"
            else (($v / 1000) | localtime | strftime("%b %-d %-I:%M%P"))
            end;

          def status_text($status):
            (number($status)) as $s |
            if $s == 1 then "normal"
            elif $s == 2 then "exhausted"
            elif $s == 3 then "unlimited"
            else "unknown"
            end;

          def metric($percent; $status; $remains; $reset):
            {
              percent: number($percent),
              percentText: pct_text($percent),
              status: number($status),
              statusText: status_text($status),
              remainsText: duration_text($remains),
              resetText: time_text($reset)
            };

          def metric_class($percent; $status):
            (number($percent)) as $p |
            (number($status)) as $s |
            if $s == 2 or $p == null or $p < 10 then "critical"
            elif $p < 25 then "warning"
            else "ok"
            end;

          def worst_class($a; $b):
            if $a == "critical" or $b == "critical" then "critical"
            elif $a == "warning" or $b == "warning" then "warning"
            else "ok"
            end;

          ($quota[0] // {}) as $q |
          (number($q.base_resp.status_code // 0) // 0) as $base_code |
          (($q.base_resp.status_msg // "success") | tostring) as $base_msg |
          if $base_code != 0 then
            {
              ok: false,
              class: "critical",
              status: "api",
              title: "MiniMax quota error",
              message: "MiniMax API returned " + ($base_code | tostring) + ": " + $base_msg,
              modelName: "",
              baseStatus: $base_code,
              baseMessage: $base_msg,
              interval: {},
              weekly: {}
            }
          else
            ($q.model_remains // []) as $models |
            ([ $models[]? | select(.model_name == $model) ][0]
              // [ $models[]? | select(.model_name != "video") ][0]
              // null) as $selected |
            if $selected == null then
              {
                ok: false,
                class: "critical",
                status: "missing_model",
                title: "MiniMax quota unavailable",
                message: "No usable non-video MiniMax quota row was returned.",
                modelName: "",
                baseStatus: $base_code,
                baseMessage: $base_msg,
                interval: {},
                weekly: {}
              }
            else
              (metric(
                $selected.current_interval_remaining_percent;
                $selected.current_interval_status;
                $selected.remains_time;
                $selected.end_time
              )) as $interval |
              (metric(
                $selected.current_weekly_remaining_percent;
                $selected.current_weekly_status;
                $selected.weekly_remains_time;
                $selected.weekly_end_time
              )) as $weekly |
              (worst_class(
                metric_class($interval.percent; $interval.status);
                metric_class($weekly.percent; $weekly.status)
              )) as $class |
              {
                ok: true,
                class: $class,
                status: "ok",
                title: "MiniMax Plus quota",
                modelName: (($selected.model_name // $model) | tostring),
                baseStatus: $base_code,
                baseMessage: $base_msg,
                generatedAtText: time_text(now * 1000),
                interval: $interval,
                weekly: $weekly
              }
            end
          end
          ' 2>"$tmp/jq.err")"; then
          json_error \
            "parse" \
            "MiniMax quota parse error" \
            "Failed to parse MiniMax quota JSON."
          exit 0
        fi

        printf '%s\n' "$output"
      '';
  };

  script = pkgs.self.mkScript {
    name = "waybar-minimax-quota";
    path = with pkgs; [jq];
    env.MINIMAX_QUOTA_ICON = icon;
    text =
      # bash
      ''
        json() {
          local text="$1"
          local tooltip="$2"
          local class="$3"

          jq -cn \
            --arg text "$text" \
            --arg tooltip "$(printf '%b' "$tooltip")" \
            --arg class "$class" \
            '{text: $text, tooltip: $tooltip, class: $class}'
        }

        if ! data="$(${lib.getExe quotaData})"; then
          json \
            "$MINIMAX_QUOTA_ICON  error" \
            "Failed to collect MiniMax quota data." \
            "critical"
          exit 0
        fi

        if ! output="$(printf '%s\n' "$data" | jq -c \
          --arg icon "$MINIMAX_QUOTA_ICON" \
          '
          def error_text($status):
            ($status | tostring) as $s |
            if $s == "missing" then "missing"
            elif $s == "parse" then "parse"
            elif $s == "api" then "api"
            else "error"
            end;

          if .ok == true then
            {
              text: ($icon + "  " + (.interval.percentText // "n/a") + " " + (.weekly.percentText // "n/a")),
              tooltip: ([
                "platform.minimax.io",
                "5 hour: " + (.interval.percentText // "n/a") + " remaining, reset in " + (.interval.remainsText // "n/a"),
                "weekly: " + (.weekly.percentText // "n/a") + " remaining, reset in " + (.weekly.remainsText // "n/a"),
                "updated: " + (.generatedAtText // "n/a")
              ] | join("\n")),
              class: (.class // "warning")
            }
          else
            {
              text: ($icon + "  " + error_text(.status // "error")),
              tooltip: (((.title // "MiniMax quota unavailable") + "\n" + (.message // "No quota data available."))),
              class: (.class // "critical")
            }
          end
          ' 2>/dev/null)"; then
          json \
            "$MINIMAX_QUOTA_ICON  parse" \
            "Failed to format MiniMax quota data." \
            "critical"
          exit 0
        fi

        printf '%s\n' "$output"
      '';
  };

  popupQml = pkgs.writeText "MiniMaxQuota.qml" (builtins.replaceStrings
    [
      "@DATA_COMMAND@"
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
      "@BASE0B@"
      "@BASE0D@"
    ]
    [
      (lib.getExe quotaData)
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
      "#${colors.base0B}"
      "#${colors.base0D}"
    ]
    (builtins.readFile ./minimax-quota.qml));

  popupToggle = pkgs.self.mkScript {
    name = "minimax-quota-popup";
    path = [qsCfg.package pkgs.systemd];
    text =
      # bash
      ''
        action="''${1:-toggle}"

        call() {
          qs ipc -c ${lib.escapeShellArg qsCfg.configName} call minimax-quota "$@"
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

            echo "minimax-quota-popup: quickshell IPC target unavailable" >&2
            exit 1
            ;;
          *)
            echo "Usage: minimax-quota-popup [toggle|show|hide|refresh]" >&2
            exit 2
            ;;
        esac
      '';
  };
in {
  options.wayland.windowManager.hyprland.waybar.minimax-quota = {
    enable = lib.mkEnableOption "MiniMax quota Waybar widget";

    command = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/npm/bin/mmx";
      description = "Path to the real mmx CLI binary used for quota polling.";
    };

    modelName = mkOption {
      type = types.str;
      default = "general";
      description = "MiniMax quota model row to display. Video rows are ignored as fallback candidates.";
    };

    interval = mkOption {
      type = types.ints.positive;
      default = 60;
      description = "Polling interval in seconds.";
    };

    popup.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the Quickshell detailed quota popup on click.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.waybar.settings.bar = {
        "custom/minimax-quota" = {
          return-type = "json";
          exec = lib.getExe script;
          format = "{text}";
          escape = false;
          max-length = 32;
          interval = cfg.interval;
          tooltip = true;
          on-click-right = "${pkgs.xdg-utils}/bin/xdg-open https://platform.minimax.io/console/usage";
          on-click =
            if cfg.popup.enable
            then "${lib.getExe popupToggle} toggle"
            else "${lib.getExe script}";
        };
      };
    }

    (mkIf cfg.popup.enable {
      home.packages = [popupToggle];

      wayland.windowManager.hyprland.quickshell = {
        enable = true;
        components = [''MiniMaxQuota {}''];
        files."MiniMaxQuota.qml" = popupQml;
      };
    })
  ]);
}
