{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.waybar.codex-lb;
  inherit (lib) mkIf mkOption types;

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
  };

  config = mkIf cfg.enable {
    programs.waybar.settings.bar = {
      "custom/codex-lb" = {
        return-type = "json";
        exec = lib.getExe script;
        interval = cfg.interval;
        tooltip = true;
        on-click = "${pkgs.xdg-utils}/bin/xdg-open ${lib.escapeShellArg cfg.url}";
      };
    };
  };
}
