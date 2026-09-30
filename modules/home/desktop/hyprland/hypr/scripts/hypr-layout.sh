#!/usr/bin/env bash
# Use the same Lua implementation as the keyboard binds, including workspace selectors.
case "${1:-next}" in
next | prev)
  hyprctl eval "require('lib.util').cycle_layout('${1:-next}')"
  ;;
dwindle | master | scrolling | monocle)
  hyprctl eval "require('lib.util').set_layout('$1')"
  ;;
*) exit 1 ;;
esac
