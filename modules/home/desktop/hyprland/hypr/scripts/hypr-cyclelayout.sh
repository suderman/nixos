#!/usr/bin/env bash
next_or_prev="${1:-next}" # next/prev
id="$(hyprctl -j activeworkspace | jq -r .id)"
layout="$(hyprctl -j activeworkspace | jq -r .tiledLayout)"

# cycle prev
# monocle > scrolling > master > dwindle
if [[ "$next_or_prev" == "prev" ]]; then

  if [[ "$layout" == "monocle" ]]; then
    hyprctl keyword workspace $id, layout:scrolling
  elif [[ "$layout" == "scrolling" ]]; then
    hyprctl keyword workspace $id, layout:master
  elif [[ "$layout" == "master" ]]; then
    hyprctl keyword workspace $id, layout:dwindle
  else
    hyprctl keyword workspace $id, layout:monocle
  fi

# cycle next
# dwindle > master > scrolling > monocle
else

  if [[ "$layout" == "dwindle" ]]; then
    hyprctl keyword workspace $id, layout:master
  elif [[ "$layout" == "master" ]]; then
    hyprctl keyword workspace $id, layout:scrolling
  elif [[ "$layout" == "scrolling" ]]; then
    hyprctl keyword workspace $id, layout:monocle
  else
    hyprctl keyword workspace $id, layout:dwindle
  fi

fi

pkill -RTMIN+8 waybar # refresh indicator
