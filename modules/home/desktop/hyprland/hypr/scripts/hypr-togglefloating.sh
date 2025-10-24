#!/usr/bin/env bash

# Save active window address
addr="$(hyprctl activewindow -j | jq -r .address)"

# Toggle floating and get status
hyprctl --batch "dispatch togglefloating address:$addr ; dispatch focuswindow address:$addr"

# If window is now floating (wasn't before), resize and centre
if [[ "$(hyprctl activewindow -j | jq -r .floating)" = "true" ]]; then
  # Rseize & center if window's x/y position is offscreen (or even exactly on the edge)
  read -r x y < <(hyprctl activewindow -j | jq -r '.at | "\(.[0]) \(.[1])"')
  if ((x <= 0 || y < 55)); then
    hyprctl --batch "dispatch resizeactive exact 50% 50% ; dispatch centerwindow 1"
  fi
fi
