#!/usr/bin/env bash
btn="$(hypr-button $@)"

# minimize to special
if [[ "$btn" == "right" ]]; then

  id="$(hyprctl activewindow -j | jq -r .workspace.id)"
  if (( id < 0 )); then 
    hyprctl dispatch movetoworkspace e+0
  else 
    hyprctl dispatch movetoworkspacesilent special
  fi

# toggle fullscreen (no waybar)
elif [[ "$btn" == "middle" ]]; then
  hyprctl dispatch fullscreen 0
  
# toggle fullscreen
else
  hyprctl dispatch fullscreen 1
fi
