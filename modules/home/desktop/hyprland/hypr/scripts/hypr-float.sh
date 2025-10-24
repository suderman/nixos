#!/usr/bin/env bash
addr="$(hyprctl activewindow -j | jq -r .address)"
is_floating="$(hyprctl activewindow -j | jq -r .floating)"
is_pinned="$(hyprctl activewindow -j | jq -r .pinned)"

# If already floating, keep floating. If also pinned, unpin
if [[ "$is_floating" == "true" ]]; then
  [[ "$is_pinned" == "true" ]] && hyprctl dispatch pin

# Float and focus
else
  hyprctl --batch "dispatch setfloating address:$addr ; dispatch focuswindow address:$addr"

  # Resize & center if window's x/y position is offscreen (or even exactly on the edge)
  read -r x y < <(hyprctl activewindow -j | jq -r '.at | "\(.[0]) \(.[1])"')
  if ((x <= 0 || y < 55)); then
    hyprctl --batch "dispatch resizeactive exact 50% 50% ; dispatch centerwindow 1"
  fi
fi
