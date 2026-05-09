#!/usr/bin/env bash
dir="${1:-forward}" # forward or reverse
addr="$(hyprctl activewindow -j | jq -r .address)"
is_floating="$(hyprctl activewindow -j | jq -r .floating)"

# Float first if needed, otherwise cycle through a cached 3x3 grid of anchor
# positions around the monitor.
# If tiled, set floating
if [[ "$is_floating" != "true" ]]; then
  hyprctl dispatch 'hl.dsp.window.float({ action = "float" })'
  hyprctl dispatch 'hl.dsp.window.center()'

# Else, cycle the floating window's position around the screen
else

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
    hyprctl dispatch 'hl.dsp.window.move({ direction = "up" })'
    hyprctl dispatch 'hl.dsp.window.move({ direction = "left" })'
    [[ "$dir" == "forward" ]] && next_pos="top_center" || next_pos="middle_left"

  elif [[ "$pos" == "top_center" ]]; then
    hyprctl dispatch 'hl.dsp.window.center()'
    hyprctl dispatch 'hl.dsp.window.move({ direction = "up" })'
    [[ "$dir" == "forward" ]] && next_pos="top_right" || next_pos="top_left"

  elif [[ "$pos" == "top_right" ]]; then
    hyprctl dispatch 'hl.dsp.window.move({ direction = "up" })'
    hyprctl dispatch 'hl.dsp.window.move({ direction = "right" })'
    [[ "$dir" == "forward" ]] && next_pos="middle_right" || next_pos="top_center"

  elif [[ "$pos" == "middle_right" ]]; then
    hyprctl dispatch 'hl.dsp.window.center()'
    hyprctl dispatch 'hl.dsp.window.move({ direction = "right" })'
    [[ "$dir" == "forward" ]] && next_pos="bottom_right" || next_pos="top_right"

  elif [[ "$pos" == "bottom_right" ]]; then
    hyprctl dispatch 'hl.dsp.window.move({ direction = "down" })'
    hyprctl dispatch 'hl.dsp.window.move({ direction = "right" })'
    [[ "$dir" == "forward" ]] && next_pos="bottom_center" || next_pos="middle_right"

  elif [[ "$pos" == "bottom_center" ]]; then
    hyprctl dispatch 'hl.dsp.window.center()'
    hyprctl dispatch 'hl.dsp.window.move({ direction = "down" })'
    [[ "$dir" == "forward" ]] && next_pos="bottom_left" || next_pos="bottom_right"

  elif [[ "$pos" == "bottom_left" ]]; then
    hyprctl dispatch 'hl.dsp.window.move({ direction = "down" })'
    hyprctl dispatch 'hl.dsp.window.move({ direction = "left" })'
    [[ "$dir" == "forward" ]] && next_pos="middle_left" || next_pos="bottom_center"

  elif [[ "$pos" == "middle_left" ]]; then
    hyprctl dispatch 'hl.dsp.window.center()'
    hyprctl dispatch 'hl.dsp.window.move({ direction = "left" })'
    [[ "$dir" == "forward" ]] && next_pos="top_left" || next_pos="bottom_left"
  fi

  # Save the next position to file
  echo "$next_pos" >$cache_dir/$window_address

fi
