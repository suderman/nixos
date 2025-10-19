#!/usr/bin/env bash
is_floating="$(hyprctl activewindow -j | jq -r .floating)"
dir="${1-l}"          # [l]eft [d]own [u]p [r]ight
x="${2-0}" y="${3-0}" # distance to move window
if [[ "$is_floating" == "true" ]]; then
  hyprctl dispatch moveactive $x $y
else
  hyprctl dispatch movewindoworgroup $dir
fi
