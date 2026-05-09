#!/usr/bin/env bash
is_floating="$(hyprctl activewindow -j | jq -r .floating)"
layout="$(hyprctl -j activeworkspace | jq -r .tiledLayout)"
dir="${1-l}"          # [l]eft [d]own [u]p [r]ight
x="${2-0}" y="${3-0}" # distance to move window
# Floating windows move by coordinates. Tiled windows use Hyprland's group-aware
# directional move dispatcher so unlocked groups still absorb windows.
if [[ "$is_floating" == "true" ]]; then
  hyprctl dispatch "hl.dsp.window.move({ x = $x, y = $y, relative = true })"
else
  hyprctl dispatch "hl.dsp.window.move({ direction = \"$dir\", group_aware = true })"
fi
