#!/usr/bin/env bash
btn="$(hypr-button $@)"

# Save active window address
addr="$(hyprctl activewindow -j | jq -r .address)"

# Get floating status
is_floating="$(hyprctl clients -j | jq ".[] | select(.address==\"$addr\") .floating")"

# toggle split/pin
if [[ "$btn" == "right" ]]; then

  # if floating, pin window
  if [[ "$is_floating" == "true" ]]; then
    hyprctl dispatch pin

  # if tiled, toggle the split
  else
    hyprctl --batch "dispatch togglesplit ; dispatch focuswindow address:$addr"
  fi

# toggle pseudo (only applies to tiled)
elif [[ "$btn" == "middle" ]]; then
  hyprctl dispatch pseudo

# toggle floating
else

  # Toggle floating and get status
  hyprctl --batch "dispatch togglefloating address:$addr ; dispatch focuswindow address:$addr"

  # If window is now floating (wasn't before), resize and centre
  if [[ "$is_floating" != "true" ]]; then
    hyprctl --batch "dispatch resizeactive exact 50% 50% ; dispatch centerwindow 1"
  fi

fi
