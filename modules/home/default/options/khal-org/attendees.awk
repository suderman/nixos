function proc(l,  m) {
  if (l ~ /^BEGIN:VEVENT/) { uid = ""; att = "" }
  else if (l ~ /^UID:/) uid = substr(l, 5)
  else if (l ~ /^ATTENDEE/ && match(tolower(l), /mailto:[^;:,]+$/)) att = att " " substr(tolower(l), RSTART + 7)
  else if (l ~ /^END:VEVENT/ && uid != "") seen[uid] = seen[uid] att
}
{ sub(/\r$/, "") }
/^[ \t]/ { cur = cur substr($0, 2); next }
{ proc(cur); cur = $0 }
END {
  proc(cur)
  for (u in seen) if (seen[u] != "") print u "\t" seen[u]
}
