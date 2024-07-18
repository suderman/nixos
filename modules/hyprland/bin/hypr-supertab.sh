#!/usr/bin/env bash

# Stack of hyprland client windows
STACK="$XDG_RUNTIME_DIR/supertab"
touch $STACK

# Move the first line to the bottom of the stack
function first_to_last {
  awk 'NR==1{store=$0;next}1;END{print store}' $STACK > $STACK.tmp
  mv $STACK.tmp $STACK
}

# Move the last line to the top of the stack
function last_to_first {
  awk '{a[NR]=$0} END {print a[NR]; for (i=1;i<NR;i++) print a[i]}' $STACK > $STACK.tmp
  mv $STACK.tmp $STACK
}

# Navigate the stack, but if no args rebuild with the current list sorted by MRU
if [[ "${1-}" == "next" ]]; then first_to_last
elif [[ "${1-}" == "prev" ]]; then last_to_first
else
  hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[] | .address' > $STACK
  first_to_last
fi

# Grab the address at the top of the stack and focus
addr="$(awk 'NR==1{print $1}' $STACK)"
hyprctl dispatch focuswindow address:$addr
