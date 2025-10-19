#!/usr/bin/env bash
toggle_or_swap="${1:-toggle}" # toggle/swap
addr="$(hyprctl activewindow -j | jq -r .address)"
is_floating="$(hyprctl activewindow -j | jq -r .floating)"

# If already tiled, togglesplit or swapsplit
if [[ "$is_floating" != "true" ]]; then
  hyprctl dispatch "${toggle_or_swap}split"

# Else, set tiled
else
  hyprctl --batch "dispatch settiled address:$addr ; dispatch focuswindow address:$addr"
fi
