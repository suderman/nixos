#!/usr/bin/env bash
layout="$(hyprctl getoption general:layout -j | jq -r .str)"
if [[ "$layout" == "dwindle" ]]; then
  hyprctl keyword general:layout scrolling
elif [[ "$layout" == "scrolling" ]]; then
  hyprctl keyword general:layout master
# elif [[ "$layout" == "master" ]]; then
#   hyprctl keyword general:layout monocle
else
  hyprctl keyword general:layout dwindle
fi
