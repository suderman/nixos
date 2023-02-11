#!/usr/bin/env bash

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

  # Final warning
  if ! ask "$(red "DANGER! Last chance to bail!") \nRe-create all disks and configurations for Linode ID ${LINODE_ID}?"; then
    return
  fi

  # Power down
  echo
  red "OK! Powering off linode. Waiting 30 seconds..."
  echo
  args="linodes shutdown $LINODE_ID"
  cmd "linode-cli $args"
  linode-cli $args
  sleep 30

  function status {
    linode-cli linodes view $LINODE_ID --format status --text --no-header
  }

  while [ "$(status)" != "offline" ]; do
    echo "...waiting another 30 seconds..."
    sleep 30
  done

  echo
  msg "Linode is now powered off"
  echo

  # Disk sizes
  LINODE_TYPE=$(linode-cli linodes view $LINODE_ID --no-header --text --format type) # g6-standard-1
  DISK_SIZE=$(linode-cli linodes type-view $LINODE_TYPE --no-header --text --format disk) # 51200
  ISO_SIZE=1024
  ROOT_SIZE=1024
  SWAP_SIZE=2048
  NIX_SIZE=$((DISK_SIZE - ISO_SIZE - ROOT_SIZE - SWAP_SIZE))

  function config-delete {
    echo "linodes config-delete $LINODE_ID $1"
  }

  # Delete all configurations
  msg "Deleting any existing configurations"
  configs=($(linode-cli linodes configs-list $LINODE_ID --text | awk 'NR > 1 {print $1}'))
  for config_id in "${configs[@]}"; do
    args="$(config-delete $config_id)"
    cmd "linode-cli $args"
    linode-cli $args
    sleep 5
  done
  echo

  function disk-delete {
    echo "linodes disk-delete $LINODE_ID $1"
  }

  # Delete all disks
  msg "Deleting any existing disks"
  disks=($(linode-cli linodes disks-list $LINODE_ID --text | awk 'NR > 1 {print $1}'))
  for disk_id in "${disks[@]}"; do
    args="$(disk-delete $disk_id)"
    cmd "linode-cli $args"
    linode-cli $args
    sleep 30
  done
  echo


  function disk-create {
    echo "linodes disk-create $LINODE_ID --label $1 --filesystem $2 --size $3 --text --no-header"
  }

  # Create the disks
  msg "Creating ISO disk"
  args="$(disk-create iso ext4 $ISO_SIZE)"
  cmd "linode-cli $args"
  ISO_ID=$(linode-cli $args | awk '{print $1}')
  ISO_DEV="--devices.sdd.disk_id $ISO_ID"
  sleep 30
  echo

  msg "Creating ROOT disk"
  args="$(disk-create root ext4 $ROOT_SIZE)"
  cmd "linode-cli $args"
  ROOT_ID=$(linode-cli $args | awk '{print $1}')
  ROOT_DEV="--devices.sda.disk_id $ROOT_ID"
  sleep 30
  echo

  msg "Creating SWAP disk"
  args="$(disk-create swap swap $SWAP_SIZE)"
  cmd "linode-cli $args"
  SWAP_ID=$(linode-cli $args | awk '{print $1}')
  SWAP_DEV="--devices.sdb.disk_id $SWAP_ID"
  sleep 30
  echo

  msg "Creating NIX disk"
  args="$(disk-create nix raw $NIX_SIZE)"
  cmd "linode-cli $args"
  NIX_ID=$(linode-cli $args | awk '{print $1}')
  NIX_DEV="--devices.sdc.disk_id $NIX_ID"
  sleep 30
  echo


  function config-create {
    local helpers="--helpers.updatedb_disabled=0 --helpers.distro=0 --helpers.modules_dep=0 --helpers.network=0 --helpers.devtmpfs_automount=0"
    echo "linodes config-create $LINODE_ID --label $1 $helpers --text --no-header $2"
  }

  # Create the first configuration
  msg "Creating INSTALLER configuration"
  args="$(config-create installer "$ROOT_DEV $SWAP_DEV $NIX_DEV $ISO_DEV --kernel linode/direct-disk --root_device /dev/sdd")"
  cmd "linode-cli $args"
  INSTALLER_ID="$(linode-cli $args | awk '{print $1}')"
  sleep 10
  echo

  # Create the second configuration
  msg "Creating NIXOS configuration"
  args="$(config-create nixos "$ROOT_DEV $SWAP_DEV $NIX_DEV --kernel linode/grub2 --root_device /dev/sda")"
  cmd "linode-cli $args"
  NIXOS_ID="$(linode-cli $args | awk '{print $1}')"
  sleep 10
  echo

  # Rescue mode
  msg "Rebooting the linode in RESCUE mode"
  args="linodes rescue $LINODE_ID $ISO_DEV"
  cmd "linode-cli $args"
  linode-cli $args
  echo

  # Final instructions
  msg "Open a Weblish console:"
  echo "https://cloud.linode.com/linodes/$LINODE_ID/lish/weblish"
  echo
  msg "From the console, download the NixOS installer onto /dev/sdd:"
  echo "iso=https://channels.nixos.org/nixos-22.11/latest-nixos-minimal-x86_64-linux.iso"
  echo "curl -L \$iso | tee >(dd of=/dev/sdd) | sha256sum"
  echo
  msg "Reboot the linode into the INSTALLER config with this command:"
  echo "linode-cli linodes reboot $LINODE_ID --config_id $INSTALLER_ID"
  echo
  msg "Open a Glish console:"
  echo "https://cloud.linode.com/linodes/$LINODE_ID/lish/glish"
  echo
  msg "Paste the following to install NixOS:"
  echo "sudo -s"
  echo "bash <(curl -sL https://github.com/suderman/nixos/raw/main/hosts/bootstrap/install.sh)"
  echo
  msg "in the installer, make the following selections:"
  echo "ROOT: sda"
  echo "BOOT: none"
  echo "SWAP: sdb"
  echo "NIX: sdc"
  echo
  msg "When finished, reboot the system into the NIXOS config with this command:"
  echo "linode-cli linodes reboot $LINODE_ID --config_id $NIXOS_ID"
  echo
  
}

# /end of linode script
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
