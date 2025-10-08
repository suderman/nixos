#!/usr/bin/env bash
action="${1-toggle}"

# count number in group
grouped_windows_count="$(hyprctl activewindow -j | jq '.grouped | length')"

# prev window in group
if [[ "$action" == "prev" ]]; then
  if ((grouped_windows_count > 1)); then
    hyprctl dispatch lockactivegroup lock
    hyprctl dispatch changegroupactive b
  else
    hyprctl dispatch togglegroup
  fi

# next window in group
elif [[ "$action" == "next" ]]; then
  if ((grouped_windows_count > 1)); then
    hyprctl dispatch lockactivegroup lock
    hyprctl dispatch changegroupactive f
  else
    hyprctl dispatch togglegroup
  fi

# toggle group lock
else
  if ((grouped_windows_count > 1)); then
    hyprctl dispatch lockactivegroup toggle
  else
    hyprctl dispatch togglegroup
  fi
fi
