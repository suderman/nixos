#!/usr/bin/env bash
target_layout="${1:-next}" # next prev dwindle master scrolling monocle
current_layout="$(hyprctl -j activeworkspace | jq -r .tiledLayout)"
id="$(hyprctl -j activeworkspace | jq -r .id)"

# Specific layouts
# dwindle master scrolling monocle

if [[ "$target_layout" == "dwindle" ]]; then
  hyprctl keyword workspace $id, layout:dwindle

elif [[ "$target_layout" == "master" ]]; then
  hyprctl keyword workspace $id, layout:master

elif [[ "$target_layout" == "scrolling" ]]; then
  hyprctl keyword workspace $id, layout:scrolling

elif [[ "$target_layout" == "monocle" ]]; then
  hyprctl keyword workspace $id, layout:monocle

# Relative layouts
# next prev

# cycle prev
# monocle > scrolling > master > dwindle
elif [[ "$target_layout" == "prev" ]]; then

  if [[ "$current_layout" == "monocle" ]]; then
    hyprctl keyword workspace $id, layout:scrolling
  elif [[ "$current_layout" == "scrolling" ]]; then
    hyprctl keyword workspace $id, layout:master
  elif [[ "$current_layout" == "master" ]]; then
    hyprctl keyword workspace $id, layout:dwindle
  else
    hyprctl keyword workspace $id, layout:monocle
  fi

# cycle next
# dwindle > master > scrolling > monocle
else

  if [[ "$current_layout" == "dwindle" ]]; then
    hyprctl keyword workspace $id, layout:master
  elif [[ "$current_layout" == "master" ]]; then
    hyprctl keyword workspace $id, layout:scrolling
  elif [[ "$current_layout" == "scrolling" ]]; then
    hyprctl keyword workspace $id, layout:monocle
  else
    hyprctl keyword workspace $id, layout:dwindle
  fi

fi

pkill -RTMIN+8 waybar # refresh indicator
