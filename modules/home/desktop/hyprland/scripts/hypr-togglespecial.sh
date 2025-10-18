#!/usr/bin/env bash

# Move window to special workspace or restore
id="$(hyprctl activewindow -j | jq -r .workspace.id)"
if ((id < 0)); then
  hyprctl dispatch movetoworkspace e+0
else
  hyprctl dispatch movetoworkspacesilent special
fi
