#!/usr/bin/env bash

# If the active window is already in a real group, toggle the lock state.
# Otherwise, create/dissolve the group like the old helper did.
# count number in group
grouped_windows_count="$(hyprctl activewindow -j | jq '.grouped | length')"

f_or_b="${1:-}" # f/b
if [[ -n "$f_or_b" ]]; then
  if [[ "$f_or_b" == "b" ]]; then
    hyprctl dispatch 'hl.dsp.group.prev()'
  else
    hyprctl dispatch 'hl.dsp.group.next()'
  fi
fi

# if a group of 2 or more windows, toggle group lock
if ((grouped_windows_count > 1)); then
  hyprctl dispatch 'hl.dsp.group.lock_active({ action = "toggle" })'

# if a group of 1 (or not a group at all) toggle group status
else
  hyprctl dispatch 'hl.dsp.group.toggle()'
fi
