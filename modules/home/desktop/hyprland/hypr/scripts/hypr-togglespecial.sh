#!/usr/bin/env bash

# Move the active window to the special workspace, or restore it back to the
# current workspace family when invoked from inside a special workspace.
id="$(hyprctl activewindow -j | jq -r .workspace.id)"
if ((id < 0)); then
  hyprctl dispatch 'hl.dsp.window.move({ workspace = "e+0" })'
else
  hyprctl dispatch 'hl.dsp.window.move({ workspace = "special" })'
fi
