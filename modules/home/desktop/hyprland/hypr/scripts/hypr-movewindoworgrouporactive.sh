#!/usr/bin/env bash
is_floating="$(hyprctl activewindow -j | jq -r .floating)"
layout="$(hyprctl -j activeworkspace | jq -r .tiledLayout)"
dir="${1-l}"          # [l]eft [d]own [u]p [r]ight
x="${2-0}" y="${3-0}" # distance to move window
if [[ "$is_floating" == "true" ]]; then
  hyprctl dispatch "hl.dsp.window.move({ x = $x, y = $y, relative = true })"
else
  hyprctl dispatch "hl.dsp.window.move({ direction = \"$dir\", group_aware = true })"
fi
