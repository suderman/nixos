#!/usr/bin/env bash

# Stack of hyprland client windows
stack="$XDG_RUNTIME_DIR/supertab"
touch $stack

# Get all window addresses or windows tagged with "mark"
get_windows() {
  [[ "${1-}" == "mark" ]] && local mark='| select(.tags | index("mark"))'
  hyprctl clients -j | jq -r "sort_by(.focusHistoryID) | .[] ${mark-} | .address"
}

# Move the first line to the bottom of the stack
first_to_last() {
  awk 'NR==1{store=$0;next}1;END{print store}' $stack >$stack.tmp
  mv $stack.tmp $stack
}

# Move the last line to the top of the stack
last_to_first() {
  awk '{a[NR]=$0} END {print a[NR]; for (i=1;i<NR;i++) print a[i]}' $stack >$stack.tmp
  mv $stack.tmp $stack
}

# Grab the address at the top of the stack and focus
focus_window() {
  addr="$(awk 'NR==1{print $1}' $stack)"
  hyprctl dispatch focuswindow address:$addr
}

# Clear all marks
if [[ "${1-}" == "clear" ]]; then
  cmds=""
  while read -r addr; do
    cmds="$cmds; dispatch tagwindow mark address:$addr"
  done < <(get_windows mark)
  hyprctl --batch "$cmds"
  notify-send -t 1000 "Clear all marks"

# Toggle individual marks
elif [[ "${1-}" == "mark" ]]; then
  hyprctl dispatch tagwindow mark

# Focus next window in stack
elif [[ "${1-}" == "next" ]]; then
  first_to_last
  focus_window

# Focus previous window in stack
elif [[ "${1-}" == "prev" ]]; then
  last_to_first
  focus_window

# If no args rebuild with the current list sorted by MRU, then focus first in stack
else
  # Try to get all marked windows
  windows="$(get_windows mark)"

  # If there are none, fall back on all windows
  if [[ -z "$windows" ]]; then
    windows="$(get_windows)"
  fi

  # Write to file and focus first in stack
  echo "$windows" >$stack
  first_to_last
  focus_window
fi
