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

# Return error
function error { 
  warn "Error: ${*-exiting}" && exit 1
}

# Show arguments
function show {
  echo "$(magenta_bold ">") $(magenta "$*")";
}

# Echo task and execute command (unless --dry-run)
function task { 
  show "${@}"
  eval "${@}" > /tmp/task
}

# Echo output from last task
function last {
  touch /tmp/task
  cat /tmp/task
}

# Echo URL, copy to clipboard, and open in browser
function url { 
  has wl-copy && echo "$1" | wl-copy
  has xdg-open && xdg-open "$1"
  echo "$(magenta_bold ">") $(cyan_underlined "$1")"
}

# Pause script until input
function pause {
  include smenu
  [[ -n "$*" ]] && info "${*}"
  smenu -d -i "continue" -a e:7 i:2,br c:2,blr <<< "Press enter to continue ..."
}

# Echo but spaces replaced with newlines
function explode {
  echo "$@" | tr ' ' '\n'
}

# warn "Wanna go on?"
# if confirm; then
#   echo "You do! :)"
# else
#   echo "You don't :("
# fi
function confirm {
  [[ "$(ask "yes no")" == "yes" ]] && return 0 || return 1 
}

# info "What is your name?"
# name="$(ask)"
# info "Which color?"
# color="$(ask "red green blue" "green")"
function ask { 
  include smenu
  # Check for 1st arg or stdin
  local words="${1}"; [[ -p /dev/stdin ]] && words="$(cat -)"
  # Check for 2nd arg as search word
  local search="${2}"; [[ -n "$search" ]] && search="-s ${search}" 
  # Check for 3rd arg as timer seconds
  local timer="${3}"; [[ -n "$timer" ]] && timer="-X ${timer}" 
  # If any words, get choice from smenu
  if [[ -n "$words" && "$words" != "-" ]]; then
    smenu -c -a i:3,b c:3,br $search $timer <<< "$words"
  # Otherwise, prompt for input
  else
    local reply=""; while [[ -z "$reply" ]]; do
      read -p "$(blue_bold :) " -i "${2}" -e reply
    done; echo "$reply"
  fi
}

# info "Choose your disk"
# disk="$(ask_disk)"
function ask_disk {
  include smenu
  local disk="refresh"
  while [[ "$disk" = "refresh" ]]; do
    disk="$(smenu -c -q -n 20 -N -d \
      -I '/__/ /g' -E '/__/ /g' \
      -i ^nvme -i ^sd -i ^hd -i ^vd \
      -i refresh -i cancel \
      -a e:4 i:6,b c:6,br  \
      -1 '(refresh|cancel)' '3,b' \
      -s /refresh \
      <<< "$(ask_disk_menu)")"
  done
  [[ "$disk" != "cancel" ]] && echo "$disk" || return 1
}

function ask_disk_menu {
  include lsblk:util-linux
  local menu="$(lsblk -o NAME,FSTYPE,LABEL,FSAVAIL,FSUSE%,MOUNTPOINT)"
  menu="${menu}\n__\n"
  menu="${menu}refresh__ cancel__"
  echo "$menu"
}

# info "Enter your IP address"
# ip="$(ask_ip 192.168.0.2)"
function ask_ip {
  include smenu
  local ip="" last_ip="" ips="" search=""
  [[ -n "$1" ]] && ip="$1" || ip="$(ask - "192.168.")"
  while :; do
    last_ip="$ip"
    if $(ping -c1 -w1 $ip >/dev/null 2>&1); then
      echo "$ip"
      return 0
    else
      [[ -n "$ip" ]] && search="-s $ip" || search=""
      ips="$(echo "${ips} ${ip}" | tr ' ' '\n' | sort | uniq | xargs)"
      ip="$(smenu -m "Retrying IP address" -q -d -a i:3,b c:3,br $search -x 10 <<< "[new] $ips [cancel]" )"
      [[ "$ip" == "[cancel]" ]] && return 1
      [[ "$ip" == "[new]" ]] && ip="$(ask - "$last_ip")"
    fi
  done
}

# Install nixos dependencies if they don't exist
# If package name doesn't match command, append pkg after colon
# Example: include git awk:gawk smenu
function include {
  local arg cmd pkg
  for arg in "$@"; do
    if [[ $arg == *":"* ]]; then
      IFS=: read -r cmd pkg <<< "$arg"
    else
      cmd="$arg"
      pkg="$arg"
    fi
    if hasnt $cmd; then
      info "Installing $pkg"
      task nix-env -iA nixos.$pkg
    fi
  done
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
