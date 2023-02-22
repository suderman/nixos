#!/usr/bin/env bash

# Install script
# sudo -s
# bash <(curl -sL https://github.com/suderman/nixos/raw/main/configurations/min/install.sh)
function main {

  if [ "$(id -u)" != "0" ]; then
    msg "Exiting, run as root."
    return
  fi

  # Banner
  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ \n"
  yellow "┃        Suderman's NixOS Installer         ┃ \n"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \n"

  # Double check we wanna do this
  if ! ask "This script is to be used on freshly partitioned disks without data worth saving.\n...onward?"; then
    return
  fi

  # List disks and partitions for reference
  echo
  blue "Disks & Partitions                            \n"
  blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ \n"
  lsblk -o NAME,FSTYPE,SIZE
  blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ \n"

  # Choose a root device (or tmpfs)
  devices=$(lsblk -o NAME -nir | xargs)
  choices=("tmpfs" $devices)
  choose -q "1.  Choose the $(yellow ROOT) device" -o choices -m 8 -v "device"
  ROOT_MNT="/mnt" ROOT_FS="tmpfs" ROOT_DEV="-"
  [ -b /dev/${device} ] && ROOT_FS="ext4" ROOT_DEV="/dev/${device}"

  # Choose a boot device (or none)
  devices=$(echo " $devices " | sed s/"\s${device}\s"/" "/g | xargs)
  choices=("none" $devices)
  choose -q "2. Choose the $(yellow BOOT) device" -o choices -m 8 -v "device"
  BOOT_MNT="-" BOOT_FS="-" BOOT_DEV="-"
  [ -b /dev/${device} ] && BOOT_MNT="/mnt/boot" BOOT_FS="vfat" BOOT_DEV="/dev/${device}"

  # Choose a swap device (or none)
  devices=$(echo " $devices " | sed s/"\s${device}\s"/" "/g | xargs)
  choices=("none" $devices)
  choose -q "3. Choose the $(yellow SWAP) device" -o choices -m 8 -v "device"
  SWAP_MNT="-" SWAP_FS="-" SWAP_DEV="-"
  [ -b /dev/${device} ] && SWAP_FS="swap" SWAP_DEV="/dev/${device}" 

  # Choose a nix device (required)
  devices=$(echo " $devices " | sed s/"\s${device}\s"/" "/g | xargs)
  choices=($devices)
  choose -q "4. Choose the $(yellow NIX) device" -o choices -m 8 -v "device"
  NIX_MNT="-" NIX_FS="-" NIX_DEV="-"
  [ -b /dev/${device} ] && NIX_MNT="/mnt/nix" NIX_FS="btrfs" NIX_DEV="/dev/${device}" 

  # Prepare padded values for table display
  _A1_____="$(printf "%-9s%s" $ROOT_MNT)" _A2_="$(printf "%-5s%s" $ROOT_FS)" _A3__________="$(printf "%-14s%s" $ROOT_DEV)"
  _B1_____="$(printf "%-9s%s" $BOOT_MNT)" _B2_="$(printf "%-5s%s" $BOOT_FS)" _B3__________="$(printf "%-14s%s" $BOOT_DEV)"
  _C1_____="$(printf "%-9s%s" $SWAP_MNT)" _C2_="$(printf "%-5s%s" $SWAP_FS)" _C3__________="$(printf "%-14s%s" $SWAP_DEV)"
  _D1_____="$(printf "%-9s%s"  $NIX_MNT)" _D2_="$(printf "%-5s%s"  $NIX_FS)" _D3__________="$(printf "%-14s%s"  $NIX_DEV)"

  # Print a delightful table summarizing what's about to happen
  echo
  purple "┏━━━━━━┳━━━━━━━━━━━┳━━━━━━━┳━━━━━━━━━━━━━━━━┓ \n"
  purple "┃ ROLE ┃ MOUNT     ┃ TYPE  ┃ DEVICE         ┃ \n"
  purple "┣━━━━━━╋━━━━━━━━━━━╋━━━━━━━╋━━━━━━━━━━━━━━━━┫ \n"
  purple "┃ Root ┃ $_A1_____ ┃ $_A2_ ┃ $_A3__________ ┃ \n"
  purple "┃ Boot ┃ $_B1_____ ┃ $_B2_ ┃ $_B3__________ ┃ \n"
  purple "┃ Swap ┃ $_C1_____ ┃ $_C2_ ┃ $_C3__________ ┃ \n"
  purple "┃ Nix  ┃ $_D1_____ ┃ $_D2_ ┃ $_D3__________ ┃ \n"
  purple "┗━━━━━━┻━━━━━━━━━━━┻━━━━━━━┻━━━━━━━━━━━━━━━━┛ \n"
  echo

  # Bail if no nix device was selected
  if [ "$NIX_DEV" = "-" ]; then
    msg "Exiting, no NIX device selected"
    return
  fi

  # Final warning
  if ! ask "$(red "DANGER! Last chance to bail!") \nFormat & prepare partitions for NixOS install?"; then
    return
  fi

  red "OK! Proceeding in 5 seconds..."
  sleep 5
  echo
  echo

  # Prepare root mount point (gonna be /mnt)
  mkdir -p $ROOT_MNT

  # If root's device is ext4, check format and mount
  if [ "$ROOT_FS" = "ext4" ]; then

    # Format this device if required
    if [ "$(lsblk $ROOT_DEV -no FSTYPE)" != "$ROOT_FS" ]; then
      msg "Formating $ROOT_DEV as $ROOT_FS for the root partition"
      cmd "mkfs.ext4 -F -L root $ROOT_DEV"
      mkfs.ext4 -L root $ROOT_DEV
      echo
    fi

    # Mount this device
    msg "Mounting $ROOT_DEV to $ROOT_MNT"
    cmd "mount $ROOT_DEV $ROOT_MNT"
    mount $ROOT_DEV $ROOT_MNT
    echo

  # Mount tmpfs at /mnt
  elif [ "$ROOT_FS" = "tmpfs" ]; then
    msg "Mounting $ROOT_FS to $ROOT_MNT"
    cmd "mount -t $ROOT_FS none $ROOT_MNT"
    mount -t tmpfs none $ROOT_MNT
    echo
  fi

  # Prepare boot mount point
  mkdir -p $BOOT_MNT

  # Format boot partition
  if [ "$BOOT_FS" = "vfat" ]; then

    msg "Formating $BOOT_DEV as $BOOT_FS for the boot partition"
    cmd "mkfs.fat -F32 $BOOT_DEV"
    mkfs.fat -F32 $BOOT_DEV
    echo

    msg "Mounting $BOOT_DEV to $BOOT_MNT"
    cmd "mount $BOOT_DEV $BOOT_MNT"
    mount $BOOT_DEV $BOOT_MNT
    echo

  fi


  # Check swap format and mount
  if [ "$SWAP_FS" = "swap" ]; then

    # Format this device if required
    if [ "$(lsblk $SWAP_DEV -no FSTYPE)" != "$SWAP_FS" ]; then
      msg "Formating $SWAP_DEV as $SWAP_FS"
      cmd "mkswap $SWAP_DEV"
      mkswap $SWAP_DEV
      echo
    fi

    # Enable swap partition
    msg "Enabling $SWAP_FS"
    cmd "swapon $SWAP_DEV"
    swapon $SWAP_DEV
    echo

  fi


  # Prepare nix mount point
  mkdir -p $NIX_MNT

  # Prepare nix btrfs and subvolumes
  if [ "$NIX_FS" = "btrfs" ]; then

    # Format this device if required
    if [ "$(lsblk $NIX_DEV -no FSTYPE)" != "$NIX_FS" ]; then
      msg "Formating $NIX_DEV as $NIX_FS for the nix partition"
      cmd "mkfs.btrfs -L nix $NIX_DEV"
      mkfs.btrfs -L nix $NIX_DEV
      echo
    fi

    # Mount nix btrfs
    msg "Mounting $NIX_DEV to $NIX_MNT"
    cmd "mount -o compress-force=zstd,noatime $NIX_DEV $NIX_MNT"
    mount -o compress-force=zstd,noatime $NIX_DEV $NIX_MNT
    echo

    # Create nested subvolume tree like so:
    # nix
    # ├── snaps
    # └── state
    #     ├── home
    #     ├── etc
    #     └── var
    #         └── log
    msg "Creating snaps subvolume"
    cmd "btrfs subvolume create $NIX_MNT/snaps"
    [ -d $NIX_MNT/snaps ] || btrfs subvolume create $NIX_MNT/snaps
    echo

    msg "Creating state subvolume"
    cmd "btrfs subvolume create $NIX_MNT/state"
    [ -d $NIX_MNT/state ] || btrfs subvolume create $NIX_MNT/state
    echo

    msg "Creating home subvolume"
    cmd "btrfs subvolume create $NIX_MNT/state/home"
    [ -d $NIX_MNT/state/home ] || btrfs subvolume create $NIX_MNT/state/home
    echo
   
    msg "Creating state var/etc directory structure"
    cmd "mkdir -p $NIX_MNT/state/{var/lib,etc/{ssh,NetworkManager/system-connections}}"
    mkdir -p $NIX_MNT/state/{var,etc/ssh}
    echo

    msg "Creating log subvolume"
    cmd "btrfs subvolume create $NIX_MNT/state/var/log"
    [ -d $NIX_MNT/state/var/log ] || btrfs subvolume create $NIX_MNT/state/var/log
    echo

  fi

  # Ensure git is installed
  command -v git >/dev/null 2>&1 || ( cmd "nix-env -iA nixos.git" && nix-env -iA nixos.git && echo )

  # Path to nixos flake
  local nixos=$NIX_MNT/state/etc/nixos

  # Clone git repo into persistant directory
  msg "Cloning nixos git repo"
  if [ -d $nixos ]; then
    cmd "cd $nixos && git pull"
    cd $nixos && git pull
  else
    cmd "git clone https://github.com/suderman/nixos $nixos"
    git clone https://github.com/suderman/nixos $nixos 
  fi
  echo

  # Path to minimal configuration
  local min=$nixos/configurations/min

  # Generate config and copy hardware-configuration.nix
  msg "Generating hardware-configuration.nix"
  cmd "nixos-generate-config --root $ROOT_MNT --dir $min"
  nixos-generate-config --root $ROOT_MNT --dir $min
  cmd "cp -f $MIN/hardware-configuration.nix $nixos/"
  cp -f $MIN/hardware-configuration.nix $nixos/

  # If linode install detected, set config.hardware.linode.enable = true;
  if [ ! -z "$LINODE" ]; then
    sed -i 's/hardware\.linode\.enable = false;/hardware.linode.enable = true;/' $min/configuration.nix
  fi

  # Personal user owns /etc/nixos 
  cmd "chown -R 1000:100 $nixos"
  chown -R 1000:100 $nixos
  echo
  
  # Run nixos installer
  msg "Installing NixOS in 5 seconds..."
  cmd "nixos-install --flake $nixos\#min --no-root-password"
  sleep 5
  nixos-install --flake $nixos\#min --no-root-password
  echo

  msg "...install is complete. \nReboot without installer media and check if it actually worked. ;-)"
  
}

# /end of installer script
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
main 
