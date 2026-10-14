# Render khal --json output (one array per day) as Org entries.
# $att holds [uid, "email email ..."] pairs read from the vdir's ICS files.
def one: gsub("\\s+"; " ") | sub("^ "; "") | sub(" $"; "");
def text:
  gsub("-::~[:~]*::-(?s:.*?)-::~[:~]*::-"; "")
  | gsub("<br\\s*/?>|</p>|</li>"; "\n"; "i") | gsub("<[^>]+>"; "")
  | gsub("&nbsp;"; " ") | gsub("&lt;"; "<") | gsub("&gt;"; ">")
  | gsub("&quot;"; "\"") | gsub("&#39;"; "'") | gsub("&amp;"; "&")
  | gsub("\r"; "") | gsub("[ \t]+\n"; "\n") | gsub("\n{3,}"; "\n\n")
  | sub("^\\s+"; "") | sub("\\s+$"; "");
def stamp:
  if .["all-day"] == "True" then
    if .start == .end then "<\(.start)>" else "<\(.start)>--<\(.end)>" end
  elif .start[0:14] == .end[0:14] then
    if .start == .end then "<\(.start)>" else "<\(.start)-\(.end[15:])>" end
  else "<\(.start)>--<\(.end)>" end;
def prop($k; $v): ($v | one) as $v | if $v == "" then empty else ":\($k): \($v)" end;

($att
  | reduce .[] as [$uid, $emails] ({}; .[$uid] += ($emails | split(" ")))
  | map_values(map(select(. != "" and (endswith("calendar.google.com") | not)))
      | unique | join(" "))) as $people
| [inputs[]] | unique_by([.uid, .start]) | sort_by(.start)
| .[]
| [ "",
    "* \(.title | one | if . == "" then "(untitled)" else . end)",
    ":PROPERTIES:",
    prop("ICAL_UID"; .uid),
    prop("STATUS"; .status),
    prop("LOCATION"; .location),
    prop("ORGANIZER"; .organizer),
    prop("ATTENDEES"; $people[.uid] // ""),
    prop("RRULE"; .["repeat-pattern"]),
    prop("URL"; .url),
    ":END:",
    stamp,
    (.description | text | select(. != "")
      | split("\n") | map(if . == "" then . else "  " + . end) | join("\n"))
  ] | join("\n")
