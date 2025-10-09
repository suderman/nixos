#!/usr/bin/env bash
# pin if floating, pseudo if tiled
is_floating="$(hyprctl activewindow -j | jq -r .floating)"
if [[ "$is_floating" == "true" ]]; then
  hyprctl dispatch pin
else
  hyprctl dispatch pseudo
fi
