#!/usr/bin/env bash
next_or_prev="${1:-next}" # next/prev
layout="$(hyprctl -j activeworkspace | jq -r .tiledLayout)"

if [[ "$layout" == "master" ]]; then

  if [[ "$next_or_prev" == "prev" ]]; then
    hyprctl dispatch layoutmsg rollprev
  else
    hyprctl dispatch layoutmsg rollnext
  fi

elif [[ "$layout" == "scrolling" ]]; then

  if [[ "$next_or_prev" == "prev" ]]; then
    # hyprctl dispatch layoutmsg move -col # -200
    hyprctl dispatch movefocus l
  else
    # hyprctl dispatch layoutmsg move +col # +200
    hyprctl dispatch movefocus r
  fi

elif [[ "$layout" == "monocle" ]]; then

  if [[ "$next_or_prev" == "prev" ]]; then
    hyprctl dispatch layoutmsg cycleprev
  else
    hyprctl dispatch layoutmsg cyclenext
  fi

else # dwindle

  if [[ "$next_or_prev" == "prev" ]]; then
    hyprctl dispatch cyclenext prev
  else
    hyprctl dispatch cyclenext
  fi

fi
