#!/usr/bin/env bash

# Disperse group (if exists) else kill window
grouped_windows_count="$(hyprctl activewindow -j | jq '.grouped | length')"
if ((grouped_windows_count > 1)); then
  hyprctl dispatch togglegroup
else
  hyprctl dispatch killactive
fi
