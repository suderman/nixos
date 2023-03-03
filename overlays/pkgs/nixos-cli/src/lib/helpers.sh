#!/usr/bin/env bash

# True if command or file does exist
function has {
  if [ -e "$1" ]; then return 0; fi
  command -v "$1" >/dev/null 2>&1 && { return 0; }
  return 1
}

# True if command or file doesn't exist
function hasnt {
  if [ -e "$1" ]; then return 1; fi
  command -v "$1" >/dev/null 2>&1 && { return 1; }
  return 0
}

# True if variable is not empty
function defined {
  if [ -z "$1" ]; then return 1; fi  
  return 0
}

# True if variable is empty
function empty {
  if [ -z "$1" ]; then return 0; fi
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

# Echo task and execute command (unless --dry-run)
function task { 
  local cmd x
  case "$1" in
    "--dry-run" | "-d" ) cmd="${*:2}" ;;
    *                  ) cmd="${*}"; x=1 ;;
  esac
  echo "$(magenta_bold ">") $(magenta "$cmd")";
  [ -z "$x" ] || eval "$cmd" > /tmp/task
}

# Echo URL, copy to clipboard, and open in browser
function url { 
  has wl-copy && echo "$1" | wl-copy
  has xdg-open && xdg-open "$1"
  echo "$(magenta_bold ">") $(cyan_underlined "$1")"
}

# Pause script until input
function pause {
  echo -n "$(green_bold "#") $(green "Press") $(blue_bold "y") $(green "to continue:") " 
  local continue=""
  while [[ "$continue" != "y" ]]; do 
    read -n 1 continue; 
  done
  echo
}

# Ask confirmation, return true if [y], return false if anything else 
function ask { 
  case "$1" in
    "--warn" | "-w" ) echo -n "$(red_bold "#") $(red "${*:2}")" ;;
    "--info" | "-i" ) echo -n "$(green_bold "#") $(green "${*:2}")" ;;
    *               ) echo -n "$(green_bold "#") $(green "${*}")" ;;
  esac
  read -p " $(blue_bold y)/[$(red_bold n)] " -n 1 -r
  echo && [[ $REPLY =~ ^[Yy]$ ]]
  [ ! $? -ne 0 ] && return 0 || return 1 
}

# Echo but spaces replaced with newlines
function explode {
  echo "$@" | tr ' ' '\n'
}

# Styled fzf with label argument
function pick {
  local label
  [ -z "$1" ] || label=" $(green_bold "${*}") " 
  has fzf && fzf --border-label="$label" --border --height=30% --margin=1 --padding=1 --layout=reverse --info=hidden
}
