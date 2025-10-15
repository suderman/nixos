#!/usr/bin/env bash
action="${1:-toggle}" # toggle or clear

# List of marked hyprland client windows
marks="$XDG_RUNTIME_DIR/supertab-marks"
touch $marks

# Clear all marks
if [[ "$action" == "clear" ]]; then
  echo "" >$marks
  notify-send -t 1000 "Clear all marks"

# Toggle individual marks
elif [[ "$action" == "toggle" ]]; then

  # Active window
  addr="$(hyprctl activewindow -j | jq -r .address)"

  # If active window found in list of marks, remove it
  if grep -q "$addr" $marks; then
    grep -v "$addr" $marks >$marks.tmp
    mv "$marks".tmp $marks
    notify-send -t 1000 "Remove mark $addr"

  # If it's not there, append it
  else
    echo "$addr" >>$marks
    notify-send -t 1000 "Add mark $addr"
  fi

fi
