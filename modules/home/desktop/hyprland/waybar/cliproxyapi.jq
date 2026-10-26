# Average each quota window independently; absent windows do not contribute.
def percent: if . == null then "n/a" else (round | tostring) + "%" end;
def age_text:
  if . == null then "never" else
    ([0, (now - .)] | max | floor) as $s |
    if $s < 60 then "just now" elif $s < 3600 then "\($s / 60 | floor)m ago" else "\($s / 3600 | floor)h ago" end
  end;
def duration:
  ([0, .] | max | floor) as $s |
  if $s >= 86400 then "\($s / 86400 | floor)d \($s % 86400 / 3600 | floor)h"
  elif $s >= 3600 then "\($s / 3600 | floor)h \($s % 3600 / 60 | floor)m"
  else "\($s / 60 | floor)m" end;
def metric:
  . + {
    percentText: (.remaining | percent),
    resetText: (if .resetAt == null then "reset unknown" elif .resetAt <= now then "reset due" else "reset in " + (.resetAt - now | duration) end),
    resetAtText: (if .resetAt == null then "" else .resetAt | localtime | strftime("%a %-I:%M%P") end),
    paceMarker: (if .resetAt == null or (.seconds // 0) <= 0 then null else [0, ([100, ((.resetAt - now) / .seconds * 100)] | min)] | max end)
  };
def account:
  . + {
    stale: ((.error // "") != "" or (.fetched // 0) < now - 300),
    updatedText: (.fetched | age_text),
    windows: [.windows[] | metric],
    score: ([.windows[] | select(.name == "5 hour" or .name == "Weekly") | .remaining] | min // -1)
  } |
  .status = (if .disabled then "Paused" elif .unavailable then "Unavailable" elif .stale then "Stale" elif (.windows | length) == 0 then "Unknown" else "Ready" end);
def window_average($name; $label):
  [.[] | select(.disabled == false and .stale == false) | .windows[] | select(.name == $name) | .remaining] |
  select(length > 0) |
  {name: $name, label: $label, remaining: (add / length), count: length};
def provider($id; $title; $icon):
  [.accounts[] | select(.provider == $id) | account] as $accounts |
  ($accounts | [window_average("5 hour"; "5h"), window_average("Weekly"; "wk")]) as $windows |
  {
    id: $id, title: $title, icon: $icon,
    accounts: ($accounts | sort_by(.disabled, -.score, .label)),
    ready: ([$accounts[] | select(.status == "Ready" and .score > 0)] | length),
    count: ($accounts | length),
    windows: $windows,
    short: (if ($windows | length) == 0 then "unknown" else
      [$windows[] | "\(.label) \(.remaining | percent)"] | join(" · ") end)
  };
{
  providers: [provider("codex"; "Codex"; "󰊚"), provider("claude"; "Claude"; "✻")],
  updatedText: (.fetched | age_text),
  message: (if $failure != "" then $failure elif (.error // "") != "" then .error elif .fetched == null then "Waiting for first quota snapshot." elif .fetched < now - 300 then "Snapshot is stale. Open management to check CLIProxyAPI." else "" end)
} |
.class = (if .message != "" or any(.providers[].accounts[]; .stale) then "stale"
  elif all(.providers[] | select(.count > 0); .ready == 0) then "critical" else "ok" end) |
if $mode == "bar" then {
  text: ([.providers[] | select(.count > 0) | "\(.icon) \(.short)"] | if length == 0 then "󰊚 quota" else join("  ") end) + (if .class == "stale" then " !" else "" end),
  class,
  tooltip: ([
    "CLIProxyAPI quota. Equal-account averages per window, not pooled capacity. Paused and stale data excluded.",
    (.providers[] | select(.count > 0) | . as $provider |
      "\(.title): \(.ready)/\(.count) accounts with allowance" +
      (if (.windows | length) == 0 then "\nNo fresh quota data" else
        ([.windows[] | "\(.name): \(.remaining | percent) mean remaining (\(.count)/\($provider.count) accounts)"] | "\n" + join("\n")) end)),
    (if .message != "" then .message else empty end),
    "Click for accounts. Right-click opens management."
  ] | join("\n\n"))
} else . end
