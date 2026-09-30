#!/usr/bin/env bash
dir="${1:-next}" # next/prev

# Keep shell compatibility for waybar / ad-hoc CLI use while dispatching the
# Lua-native workspace selector syntax underneath.
# Prev workspace
if [[ $dir == "prev" ]]; then
  hyprctl dispatch 'hl.dsp.focus({ workspace = "e-1" })'

# Next workspace
else
  hyprctl dispatch 'hl.dsp.focus({ workspace = "e+1" })'
fi
