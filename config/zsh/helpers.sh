#!/usr/bin/env zsh

# True if command or file does exist
has() {
  if [ -e "$1" ]; then return 0; fi
  command -v $1 >/dev/null 2>&1 && { return 0; }
  return 1
}

# True if command or file doesn't exist
hasnt() {
  if [ -e "$1" ]; then return 1; fi
  command -v $1 >/dev/null 2>&1 && { return 1; }
  return 0
}

# True if variable is not empty
defined() {
  if [ -z "$1" ]; then return 1; fi  
  return 0
}

# True if variable is empty
undefined() {
  if [ -z "$1" ]; then return 0; fi
  return 1
}

# True if argument has error output
error() {
  local err="$($@ 2>&1 > /dev/null)"  
  if [ -z "$err" ]; then return 1; fi
  return 0
}

# Pretty messages
# echo_color black/on_red Warning message!
# echo_color prompt/yellow/on_purple This is a prompt
echo_color() {
  
  local black='\e[0;30m'  ublack='\e[4;30m'  on_black='\e[40m'  reset='\e[0m'
  local red='\e[0;31m'    ured='\e[4;31m'    on_red='\e[41m'    default='\e[0m'
  local green='\e[0;32m'  ugreen='\e[4;32m'  on_green='\e[42m'
  local yellow='\e[0;33m' uyellow='\e[4;33m' on_yellow='\e[43m'
  local blue='\e[0;34m'   ublue='\e[4;34m'   on_blue='\e[44m'
  local purple='\e[0;35m' upurple='\e[4;35m' on_purple='\e[45m'
  local cyan='\e[0;36m'   ucyan='\e[4;36m'   on_cyan='\e[46m'
  local white='\e[0;37m'  uwhite='\e[4;37m'  on_white='\e[47m'
  
  local format=""
  for color in $(echo "$1" | tr "/" "\n"); do  
    format="${format}${(P)color}"
  done
  local message="${@:2}"  
  
  printf "${format}${message}${reset}\n";
  
}

echo_line() {
  local color=$1 char=$2 line=""
  defined $1 || color="reset"
  defined $2 || char="⎯"
  for i in $(seq $(tput cols)); do
    line="${line}${char}"
  done
  echo_color $color $line
}

echo_env() {
  defined $1 || return
  local key="$1" val="${(P)1}" trim=$2
  if defined $trim; then
    val="$(echo $val | head -c $trim)[...]$(echo $val | tail -c $trim)"
  fi
  echo "$(echo_color white "${key}=")$(echo_color green "\"${val}\"")"
}

echo_run() {
  defined $1 || return
  echo "$1"
  $1
}


# Source gracefully
source() {
  if [ -f "$1" ]; then
    builtin source "$1" && return 0;
  fi
}

# Path on separate lines
path() {
  echo $PATH | tr ':' '\n'
}

# Check for environment variable, fall back on file, or use default
env_file_default() {
  local variable="${(P)1}"
  if undefined "$variable"; then
    defined "$2" && has "$2" && variable="$(cat $2)"
    if undefined "$variable"; then
      defined "$3" && variable="$3"
    fi
  fi
  echo "$variable"
}

# Append line to end of file if it doesn't exist
append() {
  if [ $# -lt 2 ] || [ ! -r "$2" ]; then
    echo 'Usage: append "line to append" /path/to/file'
  else
    grep -q "^$1" $2 || echo "$1" | tee --append $2
  fi
}

# Echos /dev/stdin or first argument if provided
input() {
  defined "$1" && echo "$1" && return 0
  test -p /dev/stdin && awk '{print}' /dev/stdin && return 0 || return 1
}

# Strip a string to only lowercase alphanumeric with hypen + underscore
slugify() {
  echo "$(input $1)" | tr -cd '[:alnum:]-.' | tr '[:upper:]' '[:lower:]' | tr '.' '_' | xargs
}

hyphenify() {
  echo "$(input $1)" | tr -cd '[:alnum:]_.' | tr '[:upper:]' '[:lower:]' | tr '.' '-' | xargs
}

node_from_fqdn() {
  echo "$(input $1)" | tr '.' ' ' | awk '{print $1}'
}

domain_from_fqdn() {
  echo "$(input $1)" | tr '.' ' ' | awk '{$1=""}1' | xargs | tr ' ' '.'
}

lines() {
  echo "$(input $1)" | tr ' ' "\n"
}

args() {
  echo "$(input $1)" | tr ' ' '\n' | sort | uniq | xargs
}

rargs() {
  echo "$(input $1)" | tr ' ' '\n' | sort | uniq | tac | xargs
}

first() {
  echo "$(input $1)" | awk '{print $1}'
}

after_first() {
  echo "$(input $1)" | awk '{$1=""}1' | xargs
}

# one command to clone or pull a git repo
git_clone_pull() {

  if [ $# -lt 2 ]; then
    echo "Usage: git_clone_pull repository directory"
    return 1
  fi

  local repository=$1
  local directory=$2

  # Check if the directory exists
  if [ -d $directory ]; then

    # Now check if it's a git repo
    if [ -d $directory/.git ]; then

      # It is? Great, let update it!
      echo "Updating $repository"
      pushd $directory > /dev/null && git pull && popd > /dev/null

    # It's not? Rename it so we can install this one
    else
      echo "Backing up existing $directory to make room for the new one!"
      mv $directory $directory.backup
    fi
  fi

  # Make sure the directory doesn't exist
  if [ ! -d $directory ]; then

    # Install repo
    echo "Installing $repository"
    git clone $repository $directory

  fi

}

