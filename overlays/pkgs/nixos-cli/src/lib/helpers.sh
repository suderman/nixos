#!/usr/bin/env bash

# True if command or file does exist
function has {
  if [[ -e "$1" ]]; then return 0; fi
  command -v "$1" >/dev/null 2>&1 && { return 0; }
  return 1
}

# True if command or file doesn't exist
function hasnt {
  if [[ -e "$1" ]]; then return 1; fi
  command -v "$1" >/dev/null 2>&1 && { return 1; }
  return 0
}

# True if variable is not empty
function defined {
  if [[ -z "$1" ]]; then return 1; fi  
  return 0
}

# True if variable is empty
function empty {
  if [[ -z "$1" ]]; then return 0; fi
  return 1
}

# Echo information
function info { 
  echo "$(green_bold "#") $(green "$*")" 
}

# Echo warning
function warn { 
  echo "$(red_bold "#") $(red "$*")" 
}

# Show arguments
function show {
  echo "$(magenta_bold ">") $(magenta "$*")";
}

# Echo task and execute command (unless --dry-run)
function task { 
  local cmd="$(strip_flags "${@}")"
  show "$cmd"
  is_dry "${@}" || eval "$cmd" > /tmp/out
}

# Echo output from last task
function out {
  touch /tmp/out
  cat /tmp/out
}


# Echo URL, copy to clipboard, and open in browser
function url { 
  has wl-copy && echo "$1" | wl-copy
  has xdg-open && xdg-open "$1"
  echo "$(magenta_bold ">") $(cyan_underlined "$1")"
}

# Pause script until input
function pause {
  info "${1-Paused}"
  smenu -d -i continue -a e:7 i:2,br c:2,blr <<< "Press enter to continue ..."
}

function is_warn {
  [[ "$1" == "--warn" || "$1" == "-w" ]] && return 0
  return 1
}

function is_dry {
  [[ "$1" == "--dry-run" || "$1" == "-d" ]] && return 0
  return 1
}

function strip_flags {
  case "$1" in
    "--warn" | "-w" | "--info" | "-i" | "--dry-run" | "-d") echo "${*:2}" ;;
    * ) echo "${*}" ;;
  esac
}

# Echo but spaces replaced with newlines
function explode {
  echo "$@" | tr ' ' '\n'
}

# if confirm --warn "Wanna go on?"; then
#   echo "You do! :)"
# else
#   echo "You don't :("
# fi
function confirm {
  local out="$(strip_flags "${@}")"
  [[ -z "$out" ]] && out="Confirm?"
  is_warn "${@}" && warn "$out" || info "$out"
  [[ "$(ask "yes no")" == "yes" ]] && return 0 || return 1 
}

# info "Which color?"
# color="$(ask red green blue)"
# info "What is your name?"
# name="$(ask)"
function ask { 
  # Check for args or stdin
  local choices="${@}"
  [[ -p /dev/stdin ]] && choices="$(cat -)"
  # If any choices, get choice from smenu
  if [[ -n "$choices" ]]; then
    smenu -a i:3,b c:3,br <<< "$choices"
  # Otherwise, prompt for input
  else
    local reply=""; while [[ -z "$reply" ]]; do
      read -p "$(blue_bold :) " -e reply
    done; echo "$reply"
  fi
}

# info "Choose your disk"
# disk="$(ask_disk)"
function ask_disk {
  # prepare menu of disks
  local menu="$(lsblk -o NAME,FSTYPE,LABEL,FSAVAIL,FSUSE%,MOUNTPOINT)"
  menu="${menu}\n__\n"
  menu="${menu}refresh__ cancel__"
  # choose disk from menu
  local disk="refresh"
  while [[ "$disk" = "refresh" ]]; do
    disk="$(smenu -c -q -n 20 -N -d \
      -I '/__/ /g' -E '/__/ /g' \
      -i ^nvme -i ^sd -i ^hd -i ^vd \
      -i refresh -i cancel \
      -a e:4 i:6,b c:6,br  \
      -1 '(refresh|cancel)' '3,b' \
      -s /refresh \
      <<< "$menu")"
  done
  [[ "$disk" != "cancel" ]] && echo "$disk" || return 1
}

# smenu formatting
# ----------------
#
# [fb]/[bg],[blru]
#
# 0: black    1: red    2: green
# 3: yellow   4: blue   5: purple
# 6: aqua     7: white  8: gray
# 
# [b]old b[l]inking [r]everse [u]nderline
#
# -N                   :: numbers added for selection
# -q                   :: hide scroll bar
# -N                   :: numbers added for selection
# -n 20                :: number of lines height
# -i '^[a-z].'         :: regex for what is selectable
# -1 '^[a-z].' '1/0,b' :: regex for formatting
# -m                   :: Message for title
# -d                   :: Clear menu after selection
# -W$'\n'              :: 
