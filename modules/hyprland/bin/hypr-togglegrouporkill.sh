#!/usr/bin/env bash
btn="$(hypr-button $@)"

# kill window within group
if [[ "$btn" == "right" ]]; then
  hyprctl dispatch killactive

# disperse group (if exists) else kill window
else
  grouped_windows_count="$(hyprctl activewindow -j | jq '.grouped | length')"
  if (( grouped_windows_count > 1 )); then
    hyprctl dispatch togglegroup
  else
    hyprctl dispatch killactive
  fi
fi
