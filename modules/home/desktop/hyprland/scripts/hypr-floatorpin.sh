#!/usr/bin/env bash
addr="$(hyprctl activewindow -j | jq -r .address)"
is_floating="$(hyprctl activewindow -j | jq -r .floating)"
is_pinned="$(hyprctl activewindow -j | jq -r .pinned)"

# If already floating, toggle pin
if [[ "$is_floating" == "true" ]]; then
  hyprctl dispatch pin

# Else, set floating and reset pin
else
  hyprctl --batch "dispatch setfloating address:$addr ; dispatch focuswindow address:$addr"
  hyprctl --batch "dispatch resizeactive exact 50% 50% ; dispatch centerwindow 1"
  [[ "$is_pinned" == "true" ]] && hyprctl dispatch pin
fi
