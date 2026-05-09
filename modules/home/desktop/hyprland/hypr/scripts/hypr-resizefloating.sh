#!/usr/bin/env bash
number="${1:-50}"
is_floating="$(hyprctl activewindow -j | jq -r .floating)"
# Resize only floating windows; tiled windows keep their layout-managed size.
if [[ "$is_floating" == "true" ]]; then
  hyprctl dispatch "hl.dsp.window.resize({ x = \"$number%\", y = \"$number%\" })"
  hyprctl dispatch 'hl.dsp.window.center()'
fi
