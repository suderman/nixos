echo -en "\0prompt\x1f\n"
if [ -z "${1-}" ]; then
  # hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[] | "\(.focusHistoryID) \(.class) :: \(.title)"'
  # echo -en "$(hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[] | "\(.focusHistoryID) \(.class) :: \(.title)\\0icon\\x1ffolder\\x1finfo\\x1f\(.focusHistoryID)"')\n"
  # echo -en "$(hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[] | "\(.class) :: \(.title)\\0icon\\x1ffolder\\x1finfo\\x1f\(.focusHistoryID)"')\n"
  # echo -en "$(hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[] | "\(.class) :: \(.title)\\0icon\\x1f\(.class)\\x1finfo\\x1f\(.focusHistoryID)"')\n"
  echo -en "$(hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[] | "\(.class) \t \(.title)\\0icon\\x1f\(.class)\\x1finfo\\x1f\(.focusHistoryID)"')\n"
else
  # env > /tmp/env.txt
  # printf -v id '%d\n' "$(echo "$@" | cut -d" " -f1)" 2>/dev/null
  id=''${ROFI_INFO-0}
  addr="$(hyprctl clients -j | jq -r ".[] | select(.focusHistoryID==$id) | .address")"
  coproc hyprctl dispatch focuswindow address:$addr 2>&1
fi
