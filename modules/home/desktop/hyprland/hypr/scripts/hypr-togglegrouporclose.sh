#!/usr/bin/env bash

# Disperse an existing group, otherwise close the active window.
grouped_windows_count="$(hyprctl activewindow -j | jq '.grouped | length')"
if ((grouped_windows_count > 1)); then
  hyprctl dispatch 'hl.dsp.group.toggle()'
else
  hyprctl dispatch 'hl.dsp.window.close()'
fi
