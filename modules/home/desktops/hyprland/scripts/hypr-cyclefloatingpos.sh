#!/usr/bin/env bash
dir="${1:-forward}" # forward or reverse
if [[ "$(hyprctl activewindow -j | jq -r .floating)" == "true" ]]; then

  # Get the cache directory and active window name
  cache_dir="$XDG_RUNTIME_DIR/hypr/cyclefloating"
  window_address="$(hyprctl activewindow -j | jq -r .address)"

  mkdir -p $cache_dir
  touch $cache_dir/$window_address

  # top_left    top_center    top_right
  # middle_left               middle_right
  # bottom_left bottom_center bottom_right
  pos="$(cat $cache_dir/$window_address)"
  next_pos="top_left"

  if [[ "$pos" == "top_left" ]]; then
    hyprctl --batch "dispatch movewindow u ; dispatch movewindow l"
    [[ "$dir" == "forward" ]] && next_pos="top_center" || next_pos="middle_left"

  elif [[ "$pos" == "top_center" ]]; then
    hyprctl --batch "dispatch centerwindow 1; dispatch movewindow u"
    [[ "$dir" == "forward" ]] && next_pos="top_right" || next_pos="top_left"

  elif [[ "$pos" == "top_right" ]]; then
    hyprctl --batch "dispatch movewindow u ; dispatch movewindow r"
    [[ "$dir" == "forward" ]] && next_pos="middle_right" || next_pos="top_center"

  elif [[ "$pos" == "middle_right" ]]; then
    hyprctl --batch "dispatch centerwindow 1 ; dispatch movewindow r"
    [[ "$dir" == "forward" ]] && next_pos="bottom_right" || next_pos="top_right"

  elif [[ "$pos" == "bottom_right" ]]; then
    hyprctl --batch "dispatch movewindow d ; dispatch movewindow r"
    [[ "$dir" == "forward" ]] && next_pos="bottom_center" || next_pos="middle_right"

  elif [[ "$pos" == "bottom_center" ]]; then
    hyprctl --batch "dispatch centerwindow 1 ; dispatch movewindow d"
    [[ "$dir" == "forward" ]] && next_pos="bottom_left" || next_pos="bottom_right"

  elif [[ "$pos" == "bottom_left" ]]; then
    hyprctl --batch "dispatch movewindow d ; dispatch movewindow l"
    [[ "$dir" == "forward" ]] && next_pos="middle_left" || next_pos="bottom_center"

  elif [[ "$pos" == "middle_left" ]]; then
    hyprctl --batch "dispatch centerwindow 1 ; dispatch movewindow l"
    [[ "$dir" == "forward" ]] && next_pos="top_left" || next_pos="bottom_left"
  fi

  # Save the next position to file
  echo "$next_pos" >$cache_dir/$window_address

fi
