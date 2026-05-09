#!/usr/bin/env bash
next_or_prev="${1:-next}" # next/prev
layout="$(hyprctl -j activeworkspace | jq -r .tiledLayout)"

if [[ "$layout" == "master" ]]; then

  if [[ "$next_or_prev" == "prev" ]]; then
    hyprctl dispatch 'hl.dsp.layout("rollprev")'
    hyprctl dispatch 'hl.dsp.focus({ window = "master" })'
  else
    hyprctl dispatch 'hl.dsp.layout("rollnext")'
    hyprctl dispatch 'hl.dsp.focus({ window = "master" })'
  fi

elif [[ "$layout" == "scrolling" ]]; then

  if [[ "$next_or_prev" == "prev" ]]; then
    hyprctl dispatch 'hl.dsp.focus({ direction = "left" })'
  else
    hyprctl dispatch 'hl.dsp.focus({ direction = "right" })'
  fi

elif [[ "$layout" == "monocle" ]]; then

  if [[ "$next_or_prev" == "prev" ]]; then
    hyprctl dispatch 'hl.dsp.layout("cycleprev")'
  else
    hyprctl dispatch 'hl.dsp.layout("cyclenext")'
  fi

else # dwindle

  if [[ "$next_or_prev" == "prev" ]]; then
    hyprctl dispatch 'hl.dsp.window.cycle_next({ next = false })'
  else
    hyprctl dispatch 'hl.dsp.window.cycle_next()'
  fi

fi
