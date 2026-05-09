#!/usr/bin/env bash

# Fullscreen windows take precedence; otherwise this toggles the floating-window
# scratch layer for the active workspace.
fullscreen_mode="$(hyprctl activewindow -j | jq -r '.fullscreen')"
if [[ "$fullscreen_mode" != "0" ]]; then
  if [[ "$fullscreen_mode" == "1" ]]; then
    hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })'
  else
    hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'
  fi

# Otherwise, toggle visibilty of floating windows
else

  # Active workspace number
  workspace="$(hyprctl activeworkspace -j | jq -r '.id')"

  # Active window (if tiled)
  window="$(hyprctl activewindow -j | jq 'select(.floating == false) | .address')"

  floats() {
    hyprctl clients -j |
      jq -r --arg ws "$1" \
        '[.[] | select(.workspace.name == $ws and .floating == true) | .address] | .[]'
  }

  # Any floats in the hidden workspace?
  special_floats="$(floats "special:hidden$workspace")"
  if [[ -n "$special_floats" ]]; then

    # Loop all floating windows
    for float in $special_floats; do

      # Focus each window and move to regular workspace
      hyprctl dispatch "hl.dsp.focus({ window = \"address:$float\" })"
      hyprctl dispatch "hl.dsp.window.move({ workspace = \"$workspace\" })"

    done

  else

    # Loop all floating windows on regular workspace
    for float in $(floats "$workspace"); do

      # Focus each window and move to hidden workspace
      hyprctl dispatch "hl.dsp.focus({ window = \"address:$float\" })"
      hyprctl dispatch "hl.dsp.window.move({ workspace = \"special:hidden$workspace\" })"

    done

  fi

  # Focus original window (if tiled)
  if [[ -n "$window" ]]; then
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$window\" })"
  fi

fi
