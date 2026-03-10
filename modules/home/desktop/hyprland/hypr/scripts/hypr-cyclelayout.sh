#!/usr/bin/env bash
id="$(hyprctl -j activeworkspace | jq -r .id)"
layout="$(hyprctl -j activeworkspace | jq -r .tiledLayout)"

if [[ "$layout" == "dwindle" ]]; then
  hyprctl keyword workspace $id, layout:scrolling
elif [[ "$layout" == "scrolling" ]]; then
  hyprctl keyword workspace $id, layout:master
# elif [[ "$layout" == "master" ]]; then
#   hyprctl keyword workspace $id, layout:monocle
else
  hyprctl keyword workspace $id, layout:dwindle
fi
