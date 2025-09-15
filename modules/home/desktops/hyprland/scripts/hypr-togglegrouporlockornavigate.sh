#!/usr/bin/env bash
btn="$(hypr-button $@)"

# count number in group
grouped_windows_count="$(hyprctl activewindow -j | jq '.grouped | length')"

# toggle group lock
if [[ "$btn" == "right" ]]; then

  if ((grouped_windows_count > 1)); then
    hyprctl dispatch lockactivegroup toggle
  else
    hyprctl dispatch togglegroup
  fi

# prev window in group
elif [[ "$btn" == "middle" ]]; then
  if ((grouped_windows_count > 1)); then
    hyprctl dispatch lockactivegroup lock
    hyprctl dispatch changegroupactive b
  else
    hyprctl dispatch togglegroup
  fi

# next window in group
else
  if ((grouped_windows_count > 1)); then
    hyprctl dispatch lockactivegroup lock
    hyprctl dispatch changegroupactive f
  else
    hyprctl dispatch togglegroup
  fi
fi
