# Summarize Claude subscription usage for the Waybar widget and its popup.
#
# Arguments: $mode ("bar" or "popup"), $icon, $plan, $expires (token expiry in
# epoch milliseconds), $stale (why cached data could not be refreshed), $fetched
# (fetch time in epoch seconds), and either $failure with $message, or the
# slurped $usage from GET /api/oauth/usage. The API reports utilization as percent used.

def number: tonumber? // null;
def one_decimal: (. * 10 | round) / 10 | tostring | if contains(".") then . else . + ".0" end;
def pct_text: number as $v | if $v == null then "n/a" else ($v | one_decimal) + "%" end;
def signed_text: number as $v | if $v == null then "n/a" else (if $v > 0 then "+" else "" end) + ($v | one_decimal) end;

def epoch: if . == null or . == "" then null else tostring | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601? // null end;
def duration_text:
  (if . < 0 then 0 else . end | floor) as $s |
  ($s / 86400 | floor) as $days |
  ($s % 86400 / 3600 | floor) as $hours |
  ($s % 3600 / 60 | floor) as $minutes |
  if $days > 0 then "\($days)d \($hours)h"
  elif $hours > 0 then "\($hours)h \($minutes)m"
  else "\($minutes)m"
  end;

# Remaining quota, reset timing, and pace against an even burn over the window.
def metric($minutes):
  (.utilization | number) as $used |
  (.resets_at | epoch) as $reset |
  (if $reset == null then null else [0, ([1, 1 - ($reset - now) / ($minutes * 60)] | min)] | max end) as $elapsed |
  {
    percent: (if $used == null then null else 100 - $used end),
    percentText: (if $used == null then "n/a" else 100 - $used | pct_text end),
    usedText: ($used | pct_text),
    resetText: (if $reset == null then "n/a" else "in " + ($reset - now | duration_text) end),
    resetAtText: (if $reset == null then "n/a" else $reset | localtime | strftime("%a %-I:%M%P") end),
    pace: (if $used == null or $elapsed == null then null else $elapsed * 100 - $used end),
    paceMarker: (if $elapsed == null then null else 100 - $elapsed * 100 end)
  }
  | .paceText = (.pace | signed_text | if . == "n/a" then . else . + "%" end);

def severity_class:
  if . == null or . == "normal" then "ok" elif . == "warning" then "warning" else "critical" end;

def summary:
  $usage[0] as $u |
  ($u.five_hour // {} | metric(300)) as $session |
  ($u.seven_day // {} | metric(10080)) as $weekly |
  ($expires | number) as $expires_ms |
  {
    ok: true,
    status: "ok",
    class: (
      if ($session.percent // 1) <= 0 or ($weekly.percent // 1) <= 0 then "critical"
      else [($u.limits // [])[].severity | severity_class] as $classes
        | if any($classes[]; . == "critical") then "critical"
          elif any($classes[]; . == "warning") then "warning"
          else "ok"
          end
      end
    ),
    plan: ($plan | if . == "" then "Claude" else "Claude " + (.[0:1] | ascii_upcase) + .[1:] end),
    updatedText: ($fetched | number // now | localtime | strftime("%-I:%M%P")),
    staleText: (if $stale == "" then null else {ratelimited: "rate limited", offline: "offline", expired: "token expired", auth: "token rejected", missing: "credentials missing", http: "HTTP error", parse: "bad response"}[$stale] // $stale end),
    session: $session,
    weekly: $weekly,
    models: [
      {name: "Opus", window: $u.seven_day_opus},
      {name: "Sonnet", window: $u.seven_day_sonnet}
      | select(.window != null)
      | {name, metric: (.window | metric(10080))}
    ],
    extraText: (
      $u.extra_usage as $e |
      if ($e.is_enabled // false) | not then null
      elif $e.spend_limit_reached then "spend limit reached"
      elif $e.utilization != null then ($e.utilization | pct_text) + " of monthly limit used"
      else "enabled"
      end
    ),
    tokenText: (if $expires_ms == null then "n/a" else "expires in " + ($expires_ms / 1000 - now | duration_text) end)
  };

def failure:
  {
    ok: false,
    status: $failure,
    class: (if $failure == "auth" or $failure == "expired" or $failure == "ratelimited" then "warning" else "critical" end),
    title: {
      missing: "Claude credentials not found",
      ratelimited: "Claude usage rate limited",
      expired: "Claude token expired",
      auth: "Claude rejected the token",
      offline: "Claude usage unreachable",
      http: "Claude usage HTTP error",
      parse: "Claude usage parse error"
    }[$failure],
    message: $message
  };

def bar:
  if .ok then
    {
      text: "\($icon)  \(.session.percentText) \(.weekly.percentText) \(.weekly.pace | signed_text)",
      tooltip: ([
        .plan,
        "5h \(.session.percentText) left, reset \(.session.resetText) (\(.session.resetAtText))",
        "7d \(.weekly.percentText) left, reset \(.weekly.resetText) (\(.weekly.resetAtText))",
        "weekly pace \(.weekly.paceText)",
        (if .staleText then "\(.staleText); data from \(.updatedText)" else empty end)
      ] | join("\n")),
      class
    }
  else
    {text: "\($icon) \(.status)", tooltip: .message, class}
  end;

(if $failure == "" then summary else failure end)
| if $mode == "bar" then bar else . end
