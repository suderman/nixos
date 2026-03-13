#!/usr/bin/env bash
mode="${1:-main}" # default/alt
addr="$(hyprctl activewindow -j | jq -r .address)"
layout="$(hyprctl -j activeworkspace | jq -r .tiledLayout)"
is_floating="$(hyprctl activewindow -j | jq -r .floating)"

# If already tiled, togglesplit or swapsplit
if [[ "$is_floating" != "true" ]]; then

  if [[ "$layout" == "scrolling" ]]; then
    # scrolling (move window into own column)
    hyprctl dispatch layoutmsg promote

  # master (cycle orientations)
  elif [[ "$layout" == "master" ]]; then
    if [[ "$mode" == "alt" ]]; then
      hyprctl dispatch layoutmsg orientationprev
    else
      hyprctl dispatch layoutmsg orientationnext
    fi

  else
    # dwindle (toggly/swap a split)
    if [[ "$mode" == "alt" ]]; then
      hyprctl dispatch layoutmsg swapsplit
    else
      hyprctl dispatch layoutmsg togglesplit
    fi
  fi

# Else, set tiled
else
  hyprctl --batch "dispatch settiled address:$addr ; dispatch focuswindow address:$addr"
fi
