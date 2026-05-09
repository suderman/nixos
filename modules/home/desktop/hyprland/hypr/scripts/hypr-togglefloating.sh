#!/usr/bin/env bash

# Toggle floating and get status
hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })'

# If window is now floating (wasn't before), resize and centre
if [[ "$(hyprctl activewindow -j | jq -r .floating)" = "true" ]]; then
  # Rseize & center if window's x/y position is offscreen (or even exactly on the edge)
  read -r x y < <(hyprctl activewindow -j | jq -r '.at | "\(.[0]) \(.[1])"')
  if ((x <= 0 || y < 55)); then
    hyprctl dispatch 'hl.dsp.window.center()'
  fi
fi
