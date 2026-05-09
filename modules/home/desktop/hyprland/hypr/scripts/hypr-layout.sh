#!/usr/bin/env bash
target_layout="${1:-next}" # next prev dwindle master scrolling monocle
current_layout="$(hyprctl -j activeworkspace | jq -r .tiledLayout)"
id="$(hyprctl -j activeworkspace | jq -r .id)"

set_layout() {
  local layout="$1"
  hyprctl eval "hl.workspace_rule({ workspace = \"$id\", layout = \"$layout\" })"
}

# Specific layouts
# dwindle master scrolling monocle

if [[ "$target_layout" == "dwindle" ]]; then
  set_layout dwindle

elif [[ "$target_layout" == "master" ]]; then
  set_layout master

elif [[ "$target_layout" == "scrolling" ]]; then
  set_layout scrolling

elif [[ "$target_layout" == "monocle" ]]; then
  set_layout monocle

# Relative layouts
# next prev

# cycle prev
# monocle > scrolling > master > dwindle
elif [[ "$target_layout" == "prev" ]]; then

  if [[ "$current_layout" == "monocle" ]]; then
    set_layout scrolling
  elif [[ "$current_layout" == "scrolling" ]]; then
    set_layout master
  elif [[ "$current_layout" == "master" ]]; then
    set_layout dwindle
  else
    set_layout monocle
  fi

# cycle next
# dwindle > master > scrolling > monocle
else

  if [[ "$current_layout" == "dwindle" ]]; then
    set_layout master
  elif [[ "$current_layout" == "master" ]]; then
    set_layout scrolling
  elif [[ "$current_layout" == "scrolling" ]]; then
    set_layout monocle
  else
    set_layout dwindle
  fi

fi

pkill -RTMIN+8 waybar # refresh indicator
