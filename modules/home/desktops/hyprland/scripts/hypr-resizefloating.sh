#!/usr/bin/env bash
number="${1:-50}"
is_floating="$(hyprctl activewindow -j | jq -r .floating)"
if [[ "$is_floating" == "true" ]]; then
  hyprctl --batch "dispatch resizeactive exact $number% $number% ; dispatch centerwindow 1"
fi
