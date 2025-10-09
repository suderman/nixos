#!/usr/bin/env bash

# Save active window address
addr="$(hyprctl activewindow -j | jq -r .address)"

# Get floating status
is_floating="$(hyprctl clients -j | jq ".[] | select(.address==\"$addr\") .floating")"

# Toggle floating and get status
hyprctl --batch "dispatch togglefloating address:$addr ; dispatch focuswindow address:$addr"

# If window is now floating (wasn't before), resize and centre
if [[ "$is_floating" != "true" ]]; then
  hyprctl --batch "dispatch resizeactive exact 50% 50% ; dispatch centerwindow 1"
fi
