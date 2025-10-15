#!/usr/bin/env bash

# Stack of hyprland client windows
stack="$XDG_RUNTIME_DIR/supertab"
touch $stack

# Optional list of marked windows
marks="$XDG_RUNTIME_DIR/supertab-marks"
touch $marks

prune_stack() {
  if grep -q '[^[:space:]]' $marks 2>/dev/null; then
    awk 'NR==FNR { m[$1]; next } ($1 in m)' $marks $stack >$stack.tmp
    mv $stack.tmp $stack
  fi
}

# Move the first line to the bottom of the stack
first_to_last() {
  awk 'NR==1{store=$0;next}1;END{print store}' $stack >$stack.tmp
  mv $stack.tmp $stack
}

# Move the last line to the top of the stack
last_to_first() {
  awk '{a[NR]=$0} END {print a[NR]; for (i=1;i<NR;i++) print a[i]}' $stack >$stack.tmp
  mv $stack.tmp $stack
}

# Navigate the stack, but if no args rebuild with the current list sorted by MRU
if [[ "${1-}" == "next" ]]; then
  prune_stack
  first_to_last
elif [[ "${1-}" == "prev" ]]; then
  prune_stack
  last_to_first
else
  hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[] | .address' >$stack
  prune_stack
  first_to_last
fi

# # If no marks, grab the address at the top of the stack
# if ! grep -q '[^[:space:]]' "$marks" 2>/dev/null; then
#   addr="$(awk 'NR==1{print $1}' "$stack")"
#
# # Else, grab the first address that has a match in marks
# else
#   addr="$(awk 'NR==FNR { m[$1]; next } ($1 in m) { print $1; exit }' "$marks" "$stack")"
# fi

# Grab the address at the top of the stack and focus
addr="$(awk 'NR==1{print $1}' $stack)"
hyprctl dispatch focuswindow address:$addr
