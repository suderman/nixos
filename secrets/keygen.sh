#!/usr/bin/env bash
dir="/etc/nixos"

# Main function
# First agument is name of host name to generate ssh key for
# Second argmument is IP address to send this private key to
# No arguments will skip those step, but still agenix rekey with existing keys
function keygen {

  # If an argument was passed, generate a new host key with this name
  if [ ! -z "$1" ]; then
    if [ -e $dir/secrets/keys/$1.pub ]; then
      if ask "Overwrite existing \"$1\" key?"; then
        add_host $1
      fi
    else
      add_host $1
    fi
  fi

  # Write the default.nix file compiling all public keys
  write_nix 

  # Rekey secrets with agenix and restage on git
  rekey_secrets

  # If a second argument was passed, attempt to send the generated private key to this IP address
  if [ ! -z "$2" ]; then
    migrate_key $2
  fi

}


# Generate new ssh host key
function add_host {

  msg "Generating ssh host key \"root@$1\" at $dir/keys"

  # Enter keys directory
  cmd "mkdir -p $dir/keys && cd $dir/keys"
  mkdir -p $dir/keys && cd $dir/keys

  # Clear out any existing keys
  cmd "rm -f ssh_host_ed25519_key*"
  rm -f ssh_host_ed25519_key*

  # Generate a new host key
  cmd "ssh-keygen -q -N \"\" -C \"root@$1\" -t ed25519 -f ssh_host_ed25519_key"
  ssh-keygen -q -N "" -C "root@$1" -t ed25519 -f ssh_host_ed25519_key

  # Copy the public key to the secrets directory
  cmd "cp -f ssh_host_ed25519_key.pub ../secrets/keys/$1.pub"
  cp -f ssh_host_ed25519_key.pub ../secrets/keys/$1.pub

  echo

}


# Write the default.nix file compiling all public keys
function write_nix {

  # Ouput file path 
  local nix="$dir/secrets/keys/default.nix"

  # List of all key names
  local all=""

  msg "Assembling $nix"

  # Build recursive attribute set
  cmd "rec {"
  echo "rec {" > $nix

  # Read each *.pub file in the directory
  for file in $dir/secrets/keys/*.pub; do

    # Derive the attribute key from the filename
    key=$(basename "$file" ".pub")

    # Write the attribute key and value to default.nix
    cmd "  $key = \"$(cat "$file")\";"
    echo "  $key = \"$(cat "$file")\";" >> $nix

    # Collect list of key names
    all=$(echo " $all $key " | xargs)

  done

  # Finish with all, containing list of key names
  cmd "  all = [ $all ];"
  echo "  all = [ $all ];" >> $nix

  cmd "}"
  echo "}" >> $nix
  echo

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


# Attempt to send the generated private key to this IP address
function migrate_key {

  msg "Sending newly generated ssh host key to $1"

  cmd "scp $dir/keys/ssh_host_ed25519_key $USER@$1:ssh_host_ed25519_key && "
  cmd "ssh $USER@$1 \"sudo mv ssh_host_ed25519_key /nix/state/etc/ssh/ssh_host_ed25519_key\"" 

  scp $dir/keys/ssh_host_ed25519_key $USER@$1:ssh_host_ed25519_key && \
  ssh $USER@$1 "sudo mv ssh_host_ed25519_key /nix/state/etc/ssh/ssh_host_ed25519_key" 

}


# /end of keygen script
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
keygen $@
