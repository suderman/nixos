# Summarize the codex-lb dashboard for the Waybar widget and its popup.
#
# Arguments: $mode ("bar" or "popup"), $url, $icon, $alert_color, and either
# $failure with $message, or the slurped $overview, $projections, and $logs.

def number: tonumber? // null;
def one_decimal: (. * 10 | round) / 10 | tostring | if contains(".") then . else . + ".0" end;
def num_text: number as $v | if $v == null then "n/a" else $v | one_decimal end;
def pct_text: num_text | if . == "n/a" then . else . + "%" end;
def signed_text: number as $v | if $v == null then "n/a" else (if $v > 0 then "+" else "" end) + ($v | one_decimal) end;

def epoch: if . == null or . == "" then null else tostring | sub("\\.[0-9]+"; "") | fromdateiso8601? // null end;
def local_time($format; $missing): epoch as $e | if $e == null then $missing else $e | localtime | strftime($format) end;
def time_text: local_time("%b %-d %-I:%M%P"; "n/a");

def duration_text:
  (if . < 0 then 0 else . end | floor) as $s |
  ($s / 86400 | floor) as $days |
  ($s % 86400 / 3600 | floor) as $hours |
  ($s % 3600 / 60 | floor) as $minutes |
  if $days > 0 then "\($days)d \($hours)h"
  elif $hours > 0 then "\($hours)h \($minutes)m"
  else "\($minutes)m"
  end;
def reset_text: epoch as $e | if $e == null then "n/a" else "in " + ($e - now | duration_text) end;

def metric($percent; $remaining; $capacity; $reset):
  ($remaining | number) as $r |
  ($capacity | number) as $c |
  {
    percent: ($percent | number),
    percentText: ($percent | pct_text),
    creditsText: (if $r == null or $c == null then "n/a" else "\($r | num_text)/\($c | num_text) cr" end),
    resetText: ($reset | reset_text)
  };
def window_metric: metric(.remainingPercent; .remainingCredits; .capacityCredits; .resetAt);

# The 5-hour window is summed across accounts that have one.
def primary_window($accounts; $summary):
  [$accounts[] | select(.windowMinutesPrimary == 300 and .usage.primaryRemainingPercent != null)] as $five_hour |
  ($five_hour | map(.capacityCreditsPrimary // 0) | add // 0) as $capacity |
  ($five_hour | map(.remainingCreditsPrimary // 0) | add // 0) as $remaining |
  if $capacity > 0 then
    {
      remainingPercent: ($remaining / $capacity * 100),
      remainingCredits: $remaining,
      capacityCredits: $capacity,
      resetAt: ([$five_hour[].resetAtPrimary // empty] | min)
    }
  elif ($accounts | length) == 0 then $summary
  else {}
  end;

def account_name: .alias // .displayName // .email // .accountId // "account";

def account_card:
  {
    id: .accountId,
    name: account_name,
    status: (.status // "unknown"),
    plan: (if (.planType // "") == "" then "plan unknown" else .planType end),
    primary: metric(.usage.primaryRemainingPercent; .remainingCreditsPrimary; .capacityCreditsPrimary; .resetAtPrimary),
    secondary: metric(.usage.secondaryRemainingPercent; .remainingCreditsSecondary; .capacityCreditsSecondary; .resetAtSecondary),
    resetCredits: (.availableResetCredits | number),
    resetCreditExpiryText: (.resetCreditNearestExpiresAt | time_text)
  };

def log_card($names):
  {
    timeText: (.requestedAt | local_time("%-I:%M:%S%P"; "--")),
    dateText: (.requestedAt | local_time("%m/%d/%Y"; "--")),
    account: (if (.accountId // "") == "" then "Unassigned" else $names[.accountId] // .accountId end),
    model: ((.model // "--") + (if (.reasoningEffort // "") == "" then "" else " (\(.reasoningEffort))" end)),
    tokensText: (.tokens | number | if . == null then "-- tok" else "\(.) tok" end),
    costText: (.costUsd | number | if . == null then "$--" else "$\((. * 10000 | round) / 10000)" end),
    status: (.status // "unknown"),
    errorCode,
    errorMessage
  };

def summary:
  $overview[0] as $o |
  ($projections[0].weeklyCreditPace // {}) as $pace |
  ($logs[0].requests // []) as $requests |
  ($o.accounts // []) as $accounts |
  ($pace.smoothedDeltaPercent // $pace.deltaPercent) as $delta |
  ($pace.smoothedScheduleGapCredits // $pace.scheduleGapCredits) as $gap |
  ($pace.status // "unknown") as $status |
  ($pace.confidence // "unknown") as $confidence |
  ($pace.staleAccountCount // 0) as $stale |
  ($requests[0].status // "unknown") as $latest |
  {
    ok: true,
    status: "ok",
    class: (
      if $status == "danger" then "danger"
      elif $confidence == "low" or $stale > 0 then "warning"
      elif $status == "behind" or $status == "ahead" or $status == "on_track" then $status
      else "warning"
      end
    ),
    url: $url,
    lastSyncText: ($o.lastSyncAt | time_text),
    primary: (primary_window($accounts; $o.summary.primaryWindow // {}) | window_metric),
    secondary: ($o.summary.secondaryWindow // {} | window_metric),
    pace: {
      status: $status,
      delta: ($delta | number),
      deltaText: ($delta | signed_text | if . == "n/a" then . else . + "%" end),
      actualUsedText: ($pace.actualUsedPercent | pct_text),
      scheduledUsedText: ($pace.scheduledUsedPercent | pct_text),
      summaryText: "gap \($gap | signed_text) cr, shortfall \($pace.projectedShortfallCredits | num_text) cr, confidence \($confidence), stale \($stale), inactive \($pace.inactiveAccountCount // 0)"
    },
    accounts: ($accounts | map(account_card)),
    recentLogs: (($accounts | map({key: .accountId, value: account_name}) | from_entries) as $names | $requests | map(log_card($names))),
    latestLogStatus: $latest,
    latestLogNonOk: (($requests[0].status // "ok") != "ok")
  };

def failure:
  {
    ok: false,
    status: $failure,
    title: {offline: "codex-lb offline", auth: "codex-lb auth required", http: "codex-lb HTTP error", parse: "codex-lb parse error"}[$failure],
    message: $message,
    url: $url,
    accounts: [],
    recentLogs: []
  };

def window_line: "\(.percentText)\(if .creditsText == "n/a" then "" else ", " + .creditsText end), reset \(.resetText)";

def bar:
  if .ok then
    {
      text: "\(if .latestLogNonOk then "<span color=\"\($alert_color)\">\($icon)</span>" else $icon end)  \(.primary.percentText) \(.secondary.percentText) \(.pace.delta | signed_text)",
      tooltip: ([
        ($url | sub("^[A-Za-z][A-Za-z0-9+.-]*://"; "") | split("/")[0]),
        "5h " + (.primary | window_line),
        "7d " + (.secondary | window_line),
        "updated: " + .lastSyncText
      ] | join("\n")),
      class
    }
  else
    {text: "\($icon) \(.status)", tooltip: .message, class: (if .status == "auth" then "warning" else "critical" end)}
  end;

(if $failure == "" then summary else failure end)
| if $mode == "bar" then bar else . end
