#!/usr/bin/env bash

## Color functions [@bashly-upgrade colors]
## This file is a part of Bashly standard library
##
## Usage:
## Use any of the functions below to color or format a portion of a string.
##
##   echo "before $(red this is red) after"
##   echo "before $(green_bold this is green_bold) after"
##
## Color output will be disabled if `NO_COLOR` environment variable is set
## in compliance with https://no-color.org/
##
print_in_color() {
  local color="$1"
  shift
  if [[ -z ${NO_COLOR+x} ]]; then
    printf "$color%b\e[0m\n" "$*"
  else
    printf "%b\n" "$*"
  fi
}

red() { print_in_color "\e[31m" "$*"; }
green() { print_in_color "\e[32m" "$*"; }
yellow() { print_in_color "\e[33m" "$*"; }
blue() { print_in_color "\e[34m" "$*"; }
magenta() { print_in_color "\e[35m" "$*"; }
cyan() { print_in_color "\e[36m" "$*"; }
bold() { print_in_color "\e[1m" "$*"; }
underlined() { print_in_color "\e[4m" "$*"; }
red_bold() { print_in_color "\e[1;31m" "$*"; }
green_bold() { print_in_color "\e[1;32m" "$*"; }
yellow_bold() { print_in_color "\e[1;33m" "$*"; }
blue_bold() { print_in_color "\e[1;34m" "$*"; }
magenta_bold() { print_in_color "\e[1;35m" "$*"; }
cyan_bold() { print_in_color "\e[1;36m" "$*"; }
red_underlined() { print_in_color "\e[4;31m" "$*"; }
green_underlined() { print_in_color "\e[4;32m" "$*"; }
yellow_underlined() { print_in_color "\e[4;33m" "$*"; }
blue_underlined() { print_in_color "\e[4;34m" "$*"; }
magenta_underlined() { print_in_color "\e[4;35m" "$*"; }
cyan_underlined() { print_in_color "\e[4;36m" "$*"; }

# Helper functions borrowed from myself
# https://github.com/suderman/nixos/blob/main/overlays/bin/nixos-cli/src/lib/helpers.sh

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

# Echo any standard input (if exists)
function input {
  [ -t 0 ] || cat
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
  has wl-copy && echo "$1" | wl-copy # linux
  has pbcopy && echo "$1" | pbcopy #macos
  has xdg-open && xdg-open "$1" # linux
  has open && open "$1" # macos
  echo "$(magenta_bold ">") $(cyan_underlined "$1")"
}

# Pause script until input
function pause {
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
  # Check for 1st arg or stdin
  local words="${1-}"; [[ -p /dev/stdin ]] && words="$(cat -)"
  # Check for 2nd arg as search word
  local search="${2-}"; [[ -n "$search" ]] && search="-s ${search}" 
  # Check for 3rd arg as timer seconds
  local timer="${3-}"; [[ -n "$timer" ]] && timer="-X ${timer}" 
  # If any words, get choice from smenu
  if [[ -n "$words" && "$words" != "-" ]]; then
    smenu -c -a i:3,b c:3,br $search $timer <<< "$words"
  # Otherwise, prompt for input
  else
    local reply=""; while [[ -z "$reply" ]]; do
      read -p "$(blue_bold :) " -i "${2-}" -e reply
    done; echo "$reply"
  fi
}

# info "Enter your IP address"
# ip="$(ask_ip 192.168.0.2)"
function ask_ip {
  local ip="" last_ip="" ips="" search=""
  [[ -n "${1-}" ]] && ip="${1-}" || ip="$(ask - "192.168.")"
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

# Return path to flake dir
function flake {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/flake.nix" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  if [[ -f "/flake.nix" ]]; then
    echo "/"
    return 0
  fi
  return 1
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

