#!/usr/bin/env bash
is_floating="$(hyprctl activewindow -j | jq -r .floating)"
is_pinned="$(hyprctl activewindow -j | jq -r .pinned)"
read -r x y < <(hyprctl activewindow -j | jq -r '.at | "\(.[0]) \(.[1])"')

# If already floating, keep floating. If also pinned, unpin
if [[ "$is_floating" == "true" ]]; then
  [[ "$is_pinned" == "true" ]] && hyprctl dispatch 'hl.dsp.window.pin()'

# Float and focus
else
  hyprctl dispatch 'hl.dsp.window.float({ action = "float" })'

  # Resize & center if window's x/y position is offscreen (or even exactly on the edge)
  if ((x <= 0 || y < 55)); then
    hyprctl dispatch 'hl.dsp.window.center()'
  fi
fi
