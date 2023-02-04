#!/usr/bin/env bash

# This script's directory
scripts="$(dirname $(readlink -f $0))"

# This repo's directory
dir="$(dirname $(readlink -f $scripts/..))"

# Main function
function rekey {

  # If an argument passed, show usage and exit
  if [ ! -z "$1" ]; then
    [ -z "$cmd" ] && cmd="$0"
    echo "Usage: $cmd"
    return

  # Rekey secrets with agenix and restage on git
  else
    rekey_secrets
  fi

}


# Rekey secrets with agenix and restage on git
function rekey_secrets {

  # Rekey and add any new secrets
  msg "Rekeying secrets with agenix"

  cmd "cd $dir/secrets && agenix --rekey"
  cd $dir/secrets && agenix --rekey
  echo

  msg "Staging secrets directory on git"
  cmd "git add ."
  git add .
  echo

}

# /end of rekey script
# ------------------------


# Helper functions:
# -----------------------

# Colors               Underline                       Background             Color Reset        
_black_='\e[0;30m';   _underline_black_='\e[4;30m';   _on_black_='\e[40m';   _reset_='\e[0m' 
_red_='\e[0;31m';     _underline_red_='\e[4;31m';     _on_red_='\e[41m';
_green_='\e[0;32m';   _underline_green_='\e[4;32m';   _on_green_='\e[42m';
_yellow_='\e[0;33m';  _underline_yellow_='\e[4;33m';  _on_yellow_='\e[43m';
_blue_='\e[0;34m';    _underline_blue_='\e[4;34m';    _on_blue_='\e[44m';
_purple_='\e[0;35m';  _underline_purple_='\e[4;35m';  _on_purple_='\e[45m';
_cyan_='\e[0;36m';    _underline_cyan_='\e[4;36m';    _on_cyan_='\e[46m';
_white_='\e[0;37m';   _underline_white_='\e[4;37m';   _on_white_='\e[47m';

# These can be overridden
export MSG_COLOR="$_white_"
export MSG_PROMPT="$_green_=> $_reset_"

# Pretty messages
msg() { printf "$MSG_PROMPT$MSG_COLOR$1$_reset_\n"; }
cmd() { printf "$_cyan_> $1$_reset_\n"; }

# Color functions
black()  { printf "$_black_$1$MSG_COLOR"; }
red()    { printf "$_red_$1$MSG_COLOR"; }
green()  { printf "$_green_$1$MSG_COLOR"; }
yellow() { printf "$_yellow_$1$MSG_COLOR"; }
blue()   { printf "$_blue_$1$MSG_COLOR"; }
purple() { printf "$_purple_$1$MSG_COLOR"; }
cyan()   { printf "$_cyan_$1$MSG_COLOR"; }
white()  { printf "$_white_$1$MSG_COLOR"; }

# If $answer is "y", then we don't bother with user input
ask() { 
  if [[ "$answer" == "y" ]]; then return 0; fi
  printf "$MSG_PROMPT$MSG_COLOR$1$_reset_";
  read -p " y/[n] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
  if [ ! $? -ne 0 ]; then return 0; else return 1; fi
}

# /end of helper functions
# ------------------------

# DO IT
# -----
rekey $@
