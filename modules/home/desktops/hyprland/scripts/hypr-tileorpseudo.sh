#!/usr/bin/env bash
addr="$(hyprctl activewindow -j | jq -r .address)"
is_floating="$(hyprctl activewindow -j | jq -r .floating)"
is_pseudo="$(hyprctl activewindow -j | jq -r .pseudo)"

# If already tiled, toggle pseudo
if [[ "$is_floating" != "true" ]]; then
  hyprctl dispatch pseudo

# Else, set tiled and reset pseudo
else
  hyprctl --batch "dispatch settiled address:$addr ; dispatch focuswindow address:$addr"
  [[ "$is_pseudo" == "true" ]] && hyprctl dispatch pseudo
fi
