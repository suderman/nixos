#!/usr/bin/env bash

bootstrap="$(dirname $(readlink -f $0))"
dir="$(dirname $(dirname $bootstrap))"

# Main function
function linode {

  # Banner
  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ \n"
  yellow "┃         Suderman's Linode Setup           ┃ \n"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \n"

  if [ -z "$LINODE_ID" ]; then
    linodes=($(linode-cli linodes list --text --no-header | awk '{print $1"_"$2}'))
    choose -q "Choose which existing linode to prepare" -o linodes -m 8 -v "linode"
    LINODE_ID="${linode%_*}"
  fi

  # Bail if no ID was selected
  if [ -z "$LINODE_ID" ]; then
    msg "Exiting, no LINODE_ID provided"
    return
  fi

  # Look up details about this linode
  local id="$LINODE_ID" 
  local label="$(linode-cli linodes view $id --format label --no-header --text)"
  local linode_type=$(linode-cli linodes view $id --no-header --text --format type) # example: g6-standard-1
  local linode_size=$(linode-cli linodes type-view $linode_type --no-header --text --format disk) # example: 51200
  local iso_size=1024  # reserve 1GB for installer
  local root_size=1024 # reserve 1GB for root
  local swap_size=2048 # reserve 2GB for swap
  local nix_size=$((linode_size - iso_size - root_size - swap_size)) # nix uses remaining available disk
  local flags iso_flag iso_flag swap_flag nix_flag nixos_flag installer_flag


  # Final warning
  if ! ask "$(red "DANGER! Last chance to bail!") \nRe-create all disks and configurations for linode \"${label}\"?"; then
    return
  fi
  echo

  function wait_for_linode {
    printf "   "
    while [ "$(linode-cli linodes view $id --text --no-header --format status)" != "$1" ]; do
      yellow "."
      sleep 5
    done
    echo
  }

  function wait_for_disk {
    while [ "$(linode-cli linodes disk-view $id $1 --text --no-header --format status 2>/dev/null)" != "ready" ]; do
      sleep 5
    done
    echo
  }

  # Power down
  msg "OK! Powering off linode \"${label}\". Please wait..."
  run linode-cli linodes shutdown $id
  wait_for_linode "offline"
  echo


  # Delete all configurations
  msg "Deleting any existing configurations"
  configs=($(linode-cli linodes configs-list $id --text | awk 'NR > 1 {print $1}'))
  for config_id in "${configs[@]}"; do
    run linode-cli linodes config-delete $id $config_id
    sleep 5
  done
  echo

  # Delete all disks
  msg "Deleting any existing disks"
  disks=($(linode-cli linodes disks-list $id --text | awk 'NR > 1 {print $1}'))
  for disk_id in "${disks[@]}"; do
    run linode-cli linodes disk-delete $id $disk_id
    while [ "$(linode-cli linodes disk-view $id $disk_id --text --no-header --format status 2>/dev/null)" == "deleting" ]; do
      sleep 5
    done
  done
  echo


  # Shared flags
  flags="--text --no-header"

  msg "Creating ISO disk"
  run linode-cli linodes disk-create $id $flags --label iso --filesystem ext4 --size $iso_size
  disk_id="$(cat /tmp/run | awk '{print $1}')"
  iso_flag="--devices.sdd.disk_id $disk_id"
  wait_for_disk $disk_id

  msg "Creating ROOT disk"
  run linode-cli linodes disk-create $id $flags --label root --filesystem ext4 --size $root_size
  disk_id="$(cat /tmp/run | awk '{print $1}')"
  root_flag="--devices.sda.disk_id $disk_id"
  wait_for_disk $disk_id

  msg "Creating SWAP disk"
  run linode-cli linodes disk-create $id $flags --label swap --filesystem swap --size $swap_size
  disk_id="$(cat /tmp/run | awk '{print $1}')"
  swap_flag="--devices.sdb.disk_id $disk_id"
  wait_for_disk $disk_id

  msg "Creating NIX disk"
  run linode-cli linodes disk-create $id $flags --label nix --filesystem raw --size $nix_size
  disk_id="$(cat /tmp/run | awk '{print $1}')"
  nix_flag="--devices.sdc.disk_id $disk_id"
  wait_for_disk $disk_id


  # Shared flags
  flags="--text --no-header"
  flags="$flags --helpers.updatedb_disabled=0 --helpers.distro=0 --helpers.modules_dep=0 --helpers.network=0 --helpers.devtmpfs_automount=0"
  flags="$flags $root_flag $swap_flag $nix_flag"

  # Create the main configuration
  msg "Creating NIXOS configuration"
  run linode-cli linodes config-create $LINODE_ID $flags --label nixos --kernel linode/grub2 --root_device /dev/sda
  nixos_flag="--config_id $(cat /tmp/run | awk '{print $1}')"
  sleep 10
  echo

  # Create the installer configuration
  msg "Creating INSTALLER configuration"
  run linode-cli linodes config-create $LINODE_ID $flags $iso_flag --label installer --kernel linode/direct-disk --root_device /dev/sdd
  installer_flag="--config_id $(cat /tmp/run | awk '{print $1}')"
  sleep 10
  echo

  # Rescue mode
  msg "Rebooting the linode in RESCUE mode"
  run linode-cli linodes rescue $id $iso_flag
  sleep 5
  wait_for_linode "running"
  echo

  # Create ISO disk
  msg "Opening a Weblish console:"
  url "https://cloud.linode.com/linodes/$id/lish/weblish"
  echo
  msg "Paste the following to download the NixOS installer (copied to clipboard):"
  line1="iso=https://channels.nixos.org/nixos-22.11/latest-nixos-minimal-x86_64-linux.iso"
  line2="curl -L \$iso | tee >(dd of=/dev/sdd) | sha256sum"
  out $line1
  out $line2
  echo "$line1; $line2" | wl-copy
  echo
  msg "Wait until it's finished before we reboot with the INSTALLER config"
  pause
  echo

  # Installer config
  msg "Rebooting the linode..."
  run linode-cli linodes reboot $id $installer_flag
  sleep 5
  wait_for_linode "running"
  echo

  msg "Opening a Glish console:"
  url "https://cloud.linode.com/linodes/$id/lish/glish"
  echo
  msg "Paste the following to install NixOS (second line copied to clipboard):"
  echo "sudo -s"
  echo "bash <(curl -sL https://github.com/suderman/nixos/raw/main/hosts/bootstrap/install.sh)" | tee >(wl-copy)
  echo
  msg "In the NixOS installer, make the following selections:"
  cmd "ROOT: sda"
  cmd "BOOT: none"
  cmd "SWAP: sdb"
  cmd "NIX: sdc"
  echo
  msg "Wait until it's finished before we reboot with NIXOS config"
  pause
  echo

  # NixOS config
  msg "Rebooting the linode..."
  run linode-cli linodes reboot $id $nixos_flag
  sleep 5
  wait_for_linode "running"
  echo

  # Update secrets keys
  msg "Scanning new host key in 30 seconds..."
  sleep 30
  local ip="$(linode-cli linodes view $id --no-header --text --format ipv4)"
  run $dir/secrets/scripts/secrets-keyscan $ip $label --force
  echo
  msg "Commit and push to git so changes can be pulled on the new linode at /etc/nixos"
  cmd "cd $dir && git status"
  cd $dir && git status
  sleep 5

  # Test login
  msg "Opening a Weblish console:"
  url "https://cloud.linode.com/linodes/$id/lish/weblish"
  echo
  msg "Login as root, pull from git, and rebuild config (copied to clipboard):"
  line1="cd /etc/nixos; git pull"
  line2="sudo nixos-rebuild switch"
  cmd "$line1"
  cmd "$line2"
  echo "$line1; $line2" | wl-copy
  echo
  
}

# /end of linode script
# ---------------------




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
export MSG_PROMPT="$_green_:: $_reset_"
export CMD_PROMPT="$_purple_ > $_reset_"
export CMD_COLOR="$_cyan_"
export URL_PROMPT="$_purple_ > $_reset_"
export URL_COLOR="$_underline_cyan_"

# Pretty messages
msg() { printf "$MSG_PROMPT$MSG_COLOR$(echo $@)$_reset_\n"; }
out() { printf "$MSG_COLOR$(echo $@)$_reset_\n"; }
cmd() { printf "$CMD_PROMPT$CMD_COLOR$(echo $@)$_reset_\n"; }
url() { echo $1 | wl-copy; xdg-open $1; printf "$URL_PROMPT$URL_COLOR$1$_reset_\n"; }
run() { cmd "$@"; $@>/tmp/run; }

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

pause() {
  echo -n "Press y to continue: "
  local continue=""
  while [[ "$continue" != "y" ]]; do 
    read -n 1 continue; 
  done
  echo
}

# https://github.com/the0neWhoKnocks/shell-menu-select
CHAR__GREEN='\033[0;32m'
CHAR__RED='\033[0;31m'
CHAR__RESET='\033[0m'
menuStr=""
returnOrExit=""

function __hideCursor {
  printf "\033[?25l"
  
  # capture CTRL+C so cursor can be reset
  trap "__showCursor && echo '' && ${returnOrExit} 0" SIGINT
}

function __showCursor {
  printf "\033[?25h"
  trap - SIGINT
}

function __clearLastMenu {
  local msgLineCount=$(printf "$menuStr" | wc -l)
  # moves the cursor up N lines so the output overwrites it
  echo -en "\033[${msgLineCount}A"

  # clear to end of screen to ensure there's no text left behind from previous input
  [ $1 ] && tput ed
}

function __renderMenu {
  local start=0
  local selector=""
  local instruction="$1"
  local selectedIndex=$2
  local listLength=$itemsLength
  local longest=0
  local spaces=""
  menuStr="\n $instruction\n"

  # Get the longest item from the list so that we know how many spaces to add
  # to ensure there's no overlap from longer items when a list is scrolling up or down.
  for (( i=0; i<$itemsLength; i++ )); do
    if (( ${#menuItems[i]} > longest )); then
      longest=${#menuItems[i]}
    fi
  done
  spaces=$(printf ' %.0s' $(eval "echo {1.."$(($longest))"}"))

  if [ $3 -ne 0 ]; then
    listLength=$3

    if [ $selectedIndex -ge $listLength ]; then
      start=$(($selectedIndex+1-$listLength))
      listLength=$(($selectedIndex+1))
    fi
  fi

  for (( i=$start; i<$listLength; i++ )); do
    local currItem="${menuItems[i]}"
    currItemLength=${#currItem}

    if [[ $i = $selectedIndex ]]; then
      currentSelection="${currItem}"
      selector="${CHAR__GREEN}ᐅ${CHAR__RESET}"
      currItem="${CHAR__GREEN}${currItem}${CHAR__RESET}"
    else
      selector=" "
    fi

    currItem="${spaces:0:0}${currItem}${spaces:currItemLength}"

    menuStr="${menuStr}\n ${selector} ${currItem}"
  done

  menuStr="${menuStr}\n"

  # whether or not to overwrite the previous menu output
  [ $4 ] && __clearLastMenu

  printf "${menuStr}"
}

function __renderHelp {
  echo;
  echo "Usage: choose [OPTION]..."
  echo "Renders a keyboard navigable menu with a visual indicator of what's selected."
  echo;
  echo "  -h, --help               Displays this message"
  echo "  -i, --index              The initially selected index for the options"
  echo "  -m, --max                Limit how many options are displayed"
  echo "  -o, --options            An Array of options for a user to choose from"
  echo "  -q, --query              Question or statement presented to the user"
  echo "  -v, --selectionVariable  Variable the selected choice will be saved to. Defaults to the 'selectedChoice' variable."
  echo;
  echo "Example:"
  echo "  foodOptions=(\"pizza\" \"burgers\" \"chinese\" \"sushi\" \"thai\" \"italian\" \"shit\")"
  echo;
  echo "  choose -q \"What do you feel like eating?\" -o foodOptions -i 6 -m 4 -v \"firstChoice\""
  echo "  printf \"\\n First choice is '\${firstChoice}'\\n\""
  echo;
  echo "  choose -q \"Select another option in case the first isn't available\" -o foodOptions"
  echo "  printf \"\\n Second choice is '\${selectedChoice}'\\n\""
  echo;
}

function choose {
  local KEY__ARROW_UP=$(echo -e "\033[A")
  local KEY__ARROW_DOWN=$(echo -e "\033[B")
  local KEY__ENTER=$(echo -e "\n")
  local captureInput=true
  local displayHelp=false
  local maxViewable=0
  local instruction="Select an item from the list:"
  local selectedIndex=0
  
  unset selectedChoice
  unset selectionVariable
  
  if [[ "${PS1}" == "" ]]; then
    # running via script
    returnOrExit="exit"
  else
    # running via CLI
    returnOrExit="return"
  fi
  
  if [[ "${BASH}" == "" ]]; then
    printf "\n ${CHAR__RED}[ERROR] This function utilizes Bash expansion, but your current shell is \"${SHELL}\"${CHAR__RESET}\n"
    $returnOrExit 1
  elif [[ $# == 0 ]]; then
    printf "\n ${CHAR__RED}[ERROR] No arguments provided${CHAR__RESET}\n"
    __renderHelp
    $returnOrExit 1
  fi
  
  local remainingArgs=()
  while [[ $# -gt 0 ]]; do
    local key="$1"

    case $key in
      -h|--help)
        displayHelp=true
        shift
        ;;
      -i|--index)
        selectedIndex=$2
        shift 2
        ;;
      -m|--max)
        maxViewable=$2
        shift 2
        ;;
      -o|--options)
        menuItems=$2[@]
        menuItems=("${!menuItems}")
        shift 2
        ;;
      -q|--query)
        instruction="$2"
        shift 2
        ;;
      -v|--selectionVariable)
        selectionVariable="$2"
        shift 2
        ;;
      *)
        remainingArgs+=("$1")
        shift
        ;;
    esac
  done

  # just display help
  if $displayHelp; then
    __renderHelp
    $returnOrExit 0
  fi

  set -- "${remainingArgs[@]}"
  local itemsLength=${#menuItems[@]}
  
  # no menu items, at least 1 required
  if [[ $itemsLength -lt 1 ]]; then
    printf "\n ${CHAR__RED}[ERROR] No menu items provided${CHAR__RESET}\n"
    __renderHelp
    $returnOrExit 1
  fi

  __renderMenu "$instruction" $selectedIndex $maxViewable
  __hideCursor

  while $captureInput; do
    read -rsn3 key # `3` captures the escape (\033'), bracket ([), & type (A) characters.

    case "$key" in
      "$KEY__ARROW_UP")
        selectedIndex=$((selectedIndex-1))
        (( $selectedIndex < 0 )) && selectedIndex=$((itemsLength-1))

        __renderMenu "$instruction" $selectedIndex $maxViewable true
        ;;

      "$KEY__ARROW_DOWN")
        selectedIndex=$((selectedIndex+1))
        (( $selectedIndex == $itemsLength )) && selectedIndex=0

        __renderMenu "$instruction" $selectedIndex $maxViewable true
        ;;

      "$KEY__ENTER")
        __clearLastMenu true
        __showCursor
        captureInput=false
        
        if [[ "${selectionVariable}" != "" ]]; then
          printf -v "${selectionVariable}" "${currentSelection}"
        else
          selectedChoice="${currentSelection}"
        fi
        ;;
    esac
  done
}

# /end of helper functions
# ------------------------


# DO IT
# -----
linode 
