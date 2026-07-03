{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.waybar.codex-lb;
  qsCfg = config.wayland.windowManager.hyprland.quickshell;
  colors = config.lib.stylix.colors;
  inherit (lib) mkIf mkMerge mkOption optionalAttrs types;

  script = pkgs.self.mkScript {
    name = "waybar-codex-lb";
    path = with pkgs; [curl jq];
    env.CODEX_LB_URL = cfg.url;
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

        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        CODEX_LB_URL="''${CODEX_LB_URL%/}"

        fetch() {
          local path="$1"
          local output="$2"
          local error="$output.err"
          local code

          if ! code="$(curl \
            --silent \
            --show-error \
            --location \
            --max-time 10 \
            --connect-timeout 3 \
            --write-out '%{http_code}' \
            --output "$output" \
            "$CODEX_LB_URL$path" \
            2>"$error")"; then
            json \
              "codex-lb offline" \
              "Failed to reach $CODEX_LB_URL\n$(<"$error")" \
              "critical"
            exit 0
          fi

          printf '%s' "$code"
        }

        overview="$tmp/overview.json"
        projections="$tmp/projections.json"

        overview_code="$(fetch '/api/dashboard/overview?timeframe=7d' "$overview")"
        projections_code="$(fetch '/api/dashboard/projections' "$projections")"

        if [[ "$overview_code" == "401" || "$overview_code" == "403" || "$projections_code" == "401" || "$projections_code" == "403" ]]; then
          json \
            "codex-lb auth" \
            "Dashboard read access is required. Enable read-only guest access in codex-lb or provide another dashboard auth path.\n\nURL: $CODEX_LB_URL" \
            "warning"
          exit 0
        fi

        if [[ ! "$overview_code" =~ ^2 ]] || [[ ! "$projections_code" =~ ^2 ]]; then
          json \
            "codex-lb $overview_code/$projections_code" \
            "codex-lb returned HTTP $overview_code for overview and HTTP $projections_code for projections.\n\nURL: $CODEX_LB_URL" \
            "critical"
          exit 0
        fi

        if ! output="$(jq -cn \
          --slurpfile overview "$overview" \
          --slurpfile projections "$projections" \
          --arg url "$CODEX_LB_URL" \
          '
          def num_text($n):
            ($n | tonumber? // null) as $v |
            if $v == null then "n/a"
            else
              (($v * 10 | round) / 10 | tostring) as $s |
              if ($s | contains(".")) then $s else $s + ".0" end
            end;

          def pct_text($n):
            ($n | tonumber? // null) as $v |
            if $v == null then "n/a"
            else num_text($v) + "%"
            end;

          def signed_pct_text($n):
            ($n | tonumber? // null) as $v |
            if $v == null then "n/a"
            else (if $v > 0 then "+" else "" end) + num_text($v) + "%"
            end;

          def signed_num_text($n):
            ($n | tonumber? // null) as $v |
            if $v == null then "n/a"
            else (if $v > 0 then "+" else "" end) + num_text($v)
            end;

          def time_text($s):
            if $s == null or $s == "" then "n/a"
            else
              ($s | tostring | sub("\\.[0-9]+"; "")) as $iso |
              ($iso | fromdateiso8601? // null) as $epoch |
              if $epoch == null then ($iso | sub("T"; " ") | sub("Z$"; "") | .[0:16])
              else ($epoch | localtime | strftime("%b %-d %-I:%M%P"))
              end
            end;

          def window_percent($w):
            $w.remainingPercent // $w.remaining_percent // null;

          def window_remaining($w):
            $w.remainingCredits // $w.remaining_credits // null;

          def window_capacity($w):
            $w.capacityCredits // $w.capacity_credits // null;

          def window_reset($w):
            $w.resetAt // $w.reset_at // $w.resetsAt // $w.resets_at // null;

          def credit_text($remaining; $capacity):
            if $remaining == null or $capacity == null then ""
            else ", " + num_text($remaining) + "/" + num_text($capacity) + " cr"
            end;

          def window_line($w):
            pct_text(window_percent($w))
            + credit_text(window_remaining($w); window_capacity($w))
            + ", reset " + time_text(window_reset($w));

          def account_name($account):
            $account.alias
            // $account.displayName
            // $account.display_name
            // $account.email
            // $account.accountId
            // $account.account_id
            // "account";

          def account_window_line($account; $prefix):
            ($account.usage // {}) as $usage |
            if $prefix == "primary" then
              pct_text($usage.primaryRemainingPercent // $usage.primary_remaining_percent // null)
              + credit_text(
                $account.remainingCreditsPrimary // $account.remaining_credits_primary // null;
                $account.capacityCreditsPrimary // $account.capacity_credits_primary // null
              )
              + ", reset " + time_text($account.resetAtPrimary // $account.reset_at_primary // null)
            else
              pct_text($usage.secondaryRemainingPercent // $usage.secondary_remaining_percent // null)
              + credit_text(
                $account.remainingCreditsSecondary // $account.remaining_credits_secondary // null;
                $account.capacityCreditsSecondary // $account.capacity_credits_secondary // null
              )
              + ", reset " + time_text($account.resetAtSecondary // $account.reset_at_secondary // null)
            end;

          def account_lines($account):
            ($account.usage // {}) as $u |
            [
              "Account: " + account_name($account),
              "status " + (($account.status // "unknown") | tostring),
              "5h " + account_window_line($account; "primary"),
              "7d " + account_window_line($account; "secondary"),
              "plan " + ([
                $account.planType // $account.plan_type,
                $account.workspaceLabel // $account.workspace_label,
                $account.seatType // $account.seat_type
              ] | map(select(. != null and . != "") | tostring) | join(" / ")),
              if ($u.resetCreditsRemaining // $u.reset_credits_remaining // null) != null then
                "reset credits " + num_text($u.resetCreditsRemaining // $u.reset_credits_remaining)
              else empty end
            ] | join("\n");

          def pace_status($pace):
            $pace.status // "unknown";

          def pace_delta($pace):
            $pace.smoothedDeltaPercent // $pace.smoothed_delta_percent // $pace.deltaPercent // $pace.delta_percent // null;

          def pace_gap($pace):
            $pace.smoothedScheduleGapCredits // $pace.smoothed_schedule_gap_credits // $pace.scheduleGapCredits // $pace.schedule_gap_credits // null;

          def optional_line($value; $line):
            if $value == null then [] else [$line] end;

          $overview[0] as $o |
          $projections[0] as $p |
          ($o.summary.primaryWindow // $o.summary.primary_window // $o.windows.primary // {}) as $primary |
          ($o.summary.secondaryWindow // $o.summary.secondary_window // $o.windows.secondary // {}) as $secondary |
          ($p.weeklyCreditPace // $p.weekly_credit_pace // {}) as $pace |
          ($o.accounts // []) as $accounts |
          (pace_status($pace)) as $status |
          (pace_delta($pace)) as $delta |
          (pace_gap($pace)) as $gap |
          ($pace.confidence // "unknown") as $confidence |
          (($pace.staleAccountCount // $pace.stale_account_count // 0) | tonumber? // 0) as $stale |
          (($pace.inactiveAccountCount // $pace.inactive_account_count // 0) | tonumber? // 0) as $inactive |
          (if $status == "danger" then "danger"
           elif $confidence == "low" or $stale > 0 then "warning"
           elif $status == "behind" then "behind"
           elif $status == "ahead" then "ahead"
           elif $status == "on_track" then "on_track"
           else "warning"
           end) as $class |
          {
            text: (
              "󰚩  "
              + pct_text(window_percent($primary))
              + " " + pct_text(window_percent($secondary))
              + " " + signed_num_text($delta)
            ),
            tooltip: ([
              "URL: " + $url,
              "last sync: " + time_text($o.lastSyncAt // $o.last_sync_at // null),
              "",
              "Aggregate",
              "5h " + window_line($primary),
              "7d " + window_line($secondary),
              "",
              "Weekly pace",
              "  status " + ($status | tostring),
              "  actual used " + pct_text($pace.actualUsedPercent // $pace.actual_used_percent // null),
              "  scheduled used " + pct_text($pace.scheduledUsedPercent // $pace.scheduled_used_percent // null),
              "  delta " + signed_pct_text($delta),
              "  gap " + num_text($gap) + " cr",
              "  shortfall " + num_text($pace.projectedShortfallCredits // $pace.projected_shortfall_credits // null) + " cr",
              "  confidence " + ($confidence | tostring) + ", stale " + ($stale | tostring) + ", inactive " + ($inactive | tostring)
            ]
            + optional_line(
              (if ($pace.forecastBurnRateCreditsPerHour // $pace.forecast_burn_rate_credits_per_hour // null) != null and ($pace.scheduledBurnRateCreditsPerHour // $pace.scheduled_burn_rate_credits_per_hour // null) != null then true else null end);
              "  burn " + num_text($pace.forecastBurnRateCreditsPerHour // $pace.forecast_burn_rate_credits_per_hour // null) + " cr/h forecast, " + num_text($pace.scheduledBurnRateCreditsPerHour // $pace.scheduled_burn_rate_credits_per_hour // null) + " cr/h scheduled"
            )
            + optional_line(
              (if ($pace.throttleToPercent // $pace.throttle_to_percent // null) != null and ($pace.reduceByPercent // $pace.reduce_by_percent // null) != null then true else null end);
              "  throttle " + pct_text($pace.throttleToPercent // $pace.throttle_to_percent // null) + ", reduce by " + pct_text($pace.reduceByPercent // $pace.reduce_by_percent // null)
            )
            + optional_line(
              ($pace.pauseForBreakEvenHours // $pace.pause_for_break_even_hours // null);
              "  pause for break-even " + num_text($pace.pauseForBreakEvenHours // $pace.pause_for_break_even_hours // null) + " h"
            )
            + (if ($accounts | length) > 0 then ["", ($accounts | map(account_lines(.)) | join("\n\n"))] else [] end)
            | join("\n")),
            class: $class
          }
          ' 2>"$tmp/jq.err")"; then
          json \
            "codex-lb parse" \
            "Failed to parse codex-lb dashboard response.\n$(<"$tmp/jq.err")" \
            "critical"
          exit 0
        fi

        printf '%s\n' "$output"
      '';
  };

  popupData = pkgs.self.mkScript {
    name = "codex-lb-popup-data";
    path = with pkgs; [curl jq];
    env.CODEX_LB_URL = cfg.url;
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
            --arg message "$(printf '%b' "$message")" \
            --arg url "$CODEX_LB_URL" \
            '{
              ok: false,
              status: $status,
              title: $title,
              message: $message,
              url: $url,
              accounts: []
            }'
        }

        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        CODEX_LB_URL="''${CODEX_LB_URL%/}"

        fetch() {
          local path="$1"
          local output="$2"
          local error="$output.err"
          local code

          if ! code="$(curl \
            --silent \
            --show-error \
            --location \
            --max-time 10 \
            --connect-timeout 3 \
            --write-out '%{http_code}' \
            --output "$output" \
            "$CODEX_LB_URL$path" \
            2>"$error")"; then
            json_error \
              "offline" \
              "codex-lb offline" \
              "Failed to reach $CODEX_LB_URL\n$(<"$error")"
            exit 0
          fi

          printf '%s' "$code"
        }

        overview="$tmp/overview.json"
        projections="$tmp/projections.json"

        overview_code="$(fetch '/api/dashboard/overview?timeframe=7d' "$overview")"
        projections_code="$(fetch '/api/dashboard/projections' "$projections")"

        if [[ "$overview_code" == "401" || "$overview_code" == "403" || "$projections_code" == "401" || "$projections_code" == "403" ]]; then
          json_error \
            "auth" \
            "codex-lb auth required" \
            "Dashboard read access is required. Enable read-only guest access in codex-lb.\n\nURL: $CODEX_LB_URL"
          exit 0
        fi

        if [[ ! "$overview_code" =~ ^2 ]] || [[ ! "$projections_code" =~ ^2 ]]; then
          json_error \
            "http" \
            "codex-lb HTTP $overview_code/$projections_code" \
            "codex-lb returned HTTP $overview_code for overview and HTTP $projections_code for projections.\n\nURL: $CODEX_LB_URL"
          exit 0
        fi

        if ! output="$(jq -cn \
          --slurpfile overview "$overview" \
          --slurpfile projections "$projections" \
          --arg url "$CODEX_LB_URL" \
          '
          def number($n): $n | tonumber? // null;

          def num_text($n):
            (number($n)) as $v |
            if $v == null then "n/a"
            else
              (($v * 10 | round) / 10 | tostring) as $s |
              if ($s | contains(".")) then $s else $s + ".0" end
            end;

          def pct_text($n):
            (number($n)) as $v |
            if $v == null then "n/a" else num_text($v) + "%" end;

          def signed_num_text($n):
            (number($n)) as $v |
            if $v == null then "n/a" else (if $v > 0 then "+" else "" end) + num_text($v) end;

          def signed_pct_text($n):
            (number($n)) as $v |
            if $v == null then "n/a" else signed_num_text($v) + "%" end;

          def time_text($s):
            if $s == null or $s == "" then "n/a"
            else
              ($s | tostring | sub("\\.[0-9]+"; "")) as $iso |
              ($iso | fromdateiso8601? // null) as $epoch |
              if $epoch == null then ($iso | sub("T"; " ") | sub("Z$"; "") | .[0:16])
              else ($epoch | localtime | strftime("%b %-d %-I:%M%P"))
              end
            end;

          def window_percent($w): $w.remainingPercent // $w.remaining_percent // null;
          def window_remaining($w): $w.remainingCredits // $w.remaining_credits // null;
          def window_capacity($w): $w.capacityCredits // $w.capacity_credits // null;
          def window_reset($w): $w.resetAt // $w.reset_at // $w.resetsAt // $w.resets_at // null;

          def credits_text($remaining; $capacity):
            if $remaining == null or $capacity == null then "n/a"
            else num_text($remaining) + "/" + num_text($capacity) + " cr"
            end;

          def metric($percent; $remaining; $capacity; $reset):
            (number($percent)) as $p |
            (number($remaining)) as $r |
            (number($capacity)) as $c |
            {
              percent: $p,
              percentText: pct_text($p),
              remaining: $r,
              capacity: $c,
              creditsText: credits_text($r; $c),
              resetText: time_text($reset)
            };

          def window_metric($w):
            metric(window_percent($w); window_remaining($w); window_capacity($w); window_reset($w));

          def account_name($account):
            $account.alias
            // $account.displayName
            // $account.display_name
            // $account.email
            // $account.accountId
            // $account.account_id
            // "account";

          def account_plan($account):
            ([
              $account.planType // $account.plan_type,
              $account.workspaceLabel // $account.workspace_label,
              $account.seatType // $account.seat_type
            ] | map(select(. != null and . != "") | tostring) | join(" / ")) as $plan |
            if $plan == "" then "plan unknown" else $plan end;

          def account_metric($account; $prefix):
            ($account.usage // {}) as $usage |
            if $prefix == "primary" then
              metric(
                $usage.primaryRemainingPercent // $usage.primary_remaining_percent // null;
                $account.remainingCreditsPrimary // $account.remaining_credits_primary // null;
                $account.capacityCreditsPrimary // $account.capacity_credits_primary // null;
                $account.resetAtPrimary // $account.reset_at_primary // null
              )
            else
              metric(
                $usage.secondaryRemainingPercent // $usage.secondary_remaining_percent // null;
                $account.remainingCreditsSecondary // $account.remaining_credits_secondary // null;
                $account.capacityCreditsSecondary // $account.capacity_credits_secondary // null;
                $account.resetAtSecondary // $account.reset_at_secondary // null
              )
            end;

          def account_card($account):
            {
              name: account_name($account),
              status: (($account.status // "unknown") | tostring),
              plan: account_plan($account),
              primary: account_metric($account; "primary"),
              secondary: account_metric($account; "secondary")
            };

          def pace_status($pace): $pace.status // "unknown";
          def pace_delta($pace): $pace.smoothedDeltaPercent // $pace.smoothed_delta_percent // $pace.deltaPercent // $pace.delta_percent // null;
          def pace_gap($pace): $pace.smoothedScheduleGapCredits // $pace.smoothed_schedule_gap_credits // $pace.scheduleGapCredits // $pace.schedule_gap_credits // null;

          $overview[0] as $o |
          $projections[0] as $p |
          ($o.summary.primaryWindow // $o.summary.primary_window // $o.windows.primary // {}) as $primary |
          ($o.summary.secondaryWindow // $o.summary.secondary_window // $o.windows.secondary // {}) as $secondary |
          ($p.weeklyCreditPace // $p.weekly_credit_pace // {}) as $pace |
          ($o.accounts // []) as $accounts |
          (pace_status($pace)) as $status |
          (pace_delta($pace)) as $delta |
          (pace_gap($pace)) as $gap |
          ($pace.confidence // "unknown") as $confidence |
          (($pace.staleAccountCount // $pace.stale_account_count // 0) | tonumber? // 0) as $stale |
          (($pace.inactiveAccountCount // $pace.inactive_account_count // 0) | tonumber? // 0) as $inactive |
          (if $status == "danger" then "danger"
           elif $confidence == "low" or $stale > 0 then "warning"
           elif $status == "behind" then "behind"
           elif $status == "ahead" then "ahead"
           elif $status == "on_track" then "on_track"
           else "warning"
           end) as $class |
          {
            ok: true,
            status: "ok",
            class: $class,
            url: $url,
            lastSyncText: time_text($o.lastSyncAt // $o.last_sync_at // null),
            generatedAtText: time_text(now | todateiso8601),
            primary: window_metric($primary),
            secondary: window_metric($secondary),
            pace: {
              status: $status,
              delta: (number($delta)),
              deltaText: signed_pct_text($delta),
              actualUsed: (number($pace.actualUsedPercent // $pace.actual_used_percent // null)),
              actualUsedText: pct_text($pace.actualUsedPercent // $pace.actual_used_percent // null),
              scheduledUsed: (number($pace.scheduledUsedPercent // $pace.scheduled_used_percent // null)),
              scheduledUsedText: pct_text($pace.scheduledUsedPercent // $pace.scheduled_used_percent // null),
              gap: (number($gap)),
              gapText: signed_num_text($gap) + " cr",
              shortfallText: num_text($pace.projectedShortfallCredits // $pace.projected_shortfall_credits // null) + " cr",
              confidence: ($confidence | tostring),
              stale: $stale,
              inactive: $inactive,
              summaryText: (
                "gap " + signed_num_text($gap) + " cr"
                + ", shortfall " + num_text($pace.projectedShortfallCredits // $pace.projected_shortfall_credits // null) + " cr"
                + ", confidence " + ($confidence | tostring)
                + ", stale " + ($stale | tostring)
                + ", inactive " + ($inactive | tostring)
              )
            },
            accounts: ($accounts | map(account_card(.)))
          }
          ' 2>"$tmp/jq.err")"; then
          json_error \
            "parse" \
            "codex-lb parse error" \
            "Failed to parse codex-lb dashboard response.\n$(<"$tmp/jq.err")"
          exit 0
        fi

        printf '%s\n' "$output"
      '';
  };

  popupQml = pkgs.writeText "CodexLb.qml" (builtins.replaceStrings
    [
      "@DATA_COMMAND@"
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
      "@BASE0E@"
    ]
    [
      (lib.getExe popupData)
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
      "#${colors.base0E}"
    ]
    (builtins.readFile ./codex-lb.qml));

  popupToggle = pkgs.self.mkScript {
    name = "codex-lb-popup";
    path = [qsCfg.package pkgs.systemd];
    text =
      # bash
      ''
        action="''${1:-toggle}"

        call() {
          qs ipc -c ${lib.escapeShellArg qsCfg.configName} call codex-lb "$@"
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

            echo "codex-lb-popup: quickshell IPC target unavailable" >&2
            exit 1
            ;;
          *)
            echo "Usage: codex-lb-popup [toggle|show|hide|refresh]" >&2
            exit 2
            ;;
        esac
      '';
  };
in {
  options.wayland.windowManager.hyprland.waybar.codex-lb = {
    enable = lib.mkEnableOption "codex-lb Waybar quota widget";

    url = mkOption {
      type = types.str;
      default = "https://codex-lb.kit";
      example = "https://codex-lb.cog";
      description = "Base URL for the codex-lb dashboard.";
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
        "custom/codex-lb" =
          {
            return-type = "json";
            exec = lib.getExe script;
            interval = cfg.interval;
            tooltip = true;
            on-click =
              if cfg.popup.enable
              then "${lib.getExe popupToggle} toggle"
              else "${pkgs.xdg-utils}/bin/xdg-open ${lib.escapeShellArg cfg.url}";
          }
          // optionalAttrs cfg.popup.enable {
            on-click-right = "${pkgs.xdg-utils}/bin/xdg-open ${lib.escapeShellArg cfg.url}";
          };
      };
    }

    (mkIf cfg.popup.enable {
      home.packages = [popupToggle];

      wayland.windowManager.hyprland.quickshell = {
        enable = true;
        components = [''CodexLb {}''];
        files."CodexLb.qml" = popupQml;
      };
    })
  ]);
}
