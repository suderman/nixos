#!/usr/bin/env bash
#  󰽤 󰽢

handle() {
  case $1 in
  activewindowv2\>\>*)
    addr=$(hyprctl activewindow -j | jq -r .address)
    groups="$(hyprctl activewindow -j | jq -rc '.grouped as $g | length | if . < 1 then "" else $g end')"
    echo "${groups/$addr/󰽢}" | sed "s/0x[a-f0-9]\+/󰽤/g" | sed "s/[^󰽢󰽤]\+//g"
    ;;
  esac
}

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
