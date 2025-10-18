#!/usr/bin/env bash

# Active workspace number
workspace="$(hyprctl activeworkspace -j | jq -r '.id')"

# Active window (if tiled)
window="$(hyprctl activewindow -j | jq 'select(.floating == false) | .address')"

floats() {
  hyprctl clients -j |
    jq -r --arg ws "$1" \
      '[.[] | select(.workspace.name == $ws and .floating == true) | .address] | .[]'
}

# Disable animations and begin batch cmds
hyprctl keyword animations:enabled 0
cmds=""

# Any floats in the special workspace?
special_floats="$(floats "special:s$workspace")"
if [[ -n "$special_floats" ]]; then

  # Loop all floating windows
  for float in $special_floats; do

    # Focus each window and move to regular workspace
    cmds="$cmds; dispatch focuswindow address:$float"
    cmds="$cmds; dispatch movetoworkspacesilent $workspace"

  done

else

  # Loop all floating windows on regular workspace
  for float in $(floats "$workspace"); do

    # Focus each window and move to special workspace
    cmds="$cmds; dispatch focuswindow address:$float"
    cmds="$cmds; dispatch movetoworkspacesilent special:s$workspace"

  done

fi

# Focus original window (if tiled)
if [[ -n "$window" ]]; then
  cmds="$cmds; dispatch focuswindow address:$window"
fi

# Re-enable animations and run batch commands
cmds="$cmds; keyword animations:enabled 1"
hyprctl --batch "$cmds"
