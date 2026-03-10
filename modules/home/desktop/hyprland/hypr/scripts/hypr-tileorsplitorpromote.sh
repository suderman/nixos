#!/usr/bin/env bash
toggle_or_swap="${1:-toggle}" # toggle/swap
addr="$(hyprctl activewindow -j | jq -r .address)"
is_floating="$(hyprctl activewindow -j | jq -r .floating)"
layout="$(hyprctl -j activeworkspace | jq -r .tiledLayout)"

# If already tiled, togglesplit or swapsplit
if [[ "$is_floating" != "true" ]]; then

  if [[ "$layout" == "scrolling" ]]; then
    # scrolling (move window into own column)
    hyprctl dispatch layoutmsg promote
  else
    # dwindle (toggly/swap a split)
    hyprctl dispatch layoutmsg "${toggle_or_swap}split"
  fi

# Else, set tiled
else
  hyprctl --batch "dispatch settiled address:$addr ; dispatch focuswindow address:$addr"
fi
