#!/usr/bin/env bash
arg="$1"

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


  # List disks and partitions for reference
  echo
  blue "Disks & Partitions                            \n"
  blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ \n"
  lsblk -o NAME,FSTYPE,SIZE
  blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ \n"

  # Choose a disk to partition
  local disks disk
  local bbp esp swap butter
  disks=($(lsblk -nirdo NAME | xargs))
  is_linode && disk="sda" || choose -q "Choose the $(yellow disk) to partition for NixOS" -o disks -m 8 -v "disk"

  # Bail if no disk selected
  if [ ! -e /dev/$disk ]; then
    msg "Exiting, no disk selected"
    return
  fi

  # Final warning
  if ! ask "$(red "DANGER! This script will destroy any existing data on the \"$disk\" disk.")\nProceed?"; then
    return
  fi

  red "OK! Proceeding in 5 seconds..."
  sleep 5
  echo
  echo
 
  msg "Create GPT partition table"
  run parted -s /dev/$disk mklabel gpt


  # Booting GPT from bios requires BBP with ESP
  if is_bios; then

    bbp="$disk}1"
    esp="${disk}2"
    swap="${disk}3"
    butter="${disk}4"

    msg "Create BIOS boot partition ($bbp)"
    run parted -s /dev/$disk mkpart BBP 1MiB 3MiB
    run parted -s /dev/$disk set 1 bios_grub on

    msg "Create EFI system partition ($esp)"
    run parted -s /dev/$disk mkpart ESP FAT32 3MiB 1GiB
    run parted -s /dev/$disk set 2 esp on

    msg "Create swap partition ($swap)"
    run parted -s /dev/$disk mkpart Swap linux-swap 1GiB 5GiB
    run parted -s /dev/$disk set 3 swap on

  # Otherwise, the ESP alone is fine
  else

    esp="${disk}1"
    swap="${disk}2"
    butter="${disk}3"

    msg "Create EFI system partition ($esp)"
    run parted -s /dev/$disk mkpart ESP FAT32 1MiB 1GiB
    run parted -s /dev/$disk set 1 esp on

    msg "Create swap partition ($swap)"
    run parted -s /dev/$disk mkpart Swap linux-swap 1GiB 5GiB
    run parted -s /dev/$disk set 2 swap on

  fi

  msg "Create btrfs partition ($butter)"
  run parted -s /dev/$disk mkpart Butter btrfs 5GiB 100%

  msg "Format EFI system partition"
  run mkfs.fat -F32 -n ESP /dev/$esp

  msg "Enable swap partition"
  run mkswap /dev/$swap
  run swapon /dev/$swap

  msg "Format btrfs partition"
  run mkfs.btrfs -fL Butter /dev/$butter

  msg "Create btrfs subvolume structure"
  # nix
  # ├── root
  # ├── snaps
  # └── state
  #     ├── home
  #     ├── etc
  #     └── var
  #         └── log
  run mkdir -p /mnt && mount /dev/$butter /mnt
  run btrfs subvolume create /mnt/root
  run btrfs subvolume create /mnt/snaps
  run btrfs subvolume snapshot -r /mnt/root /mnt/snaps/root
  run btrfs subvolume create /mnt/state
  run btrfs subvolume create /mnt/state/home
  run mkdir -p /mnt/state/{var/lib,etc/{ssh,NetworkManager/system-connections}}
  run btrfs subvolume create /mnt/state/var/log
  run umount /mnt

  msg "Mount root"
  run mount -o subvol=root /dev/$butter /mnt

  msg "Mount nix"
  run mkdir -p /mnt/nix && mount /dev/$butter /mnt/nix

  msg "Mount boot"
  run mkdir -p /mnt/boot && mount /dev/$esp /mnt/boot

  # Ensure git is installed
  command -v git >/dev/null 2>&1 || ( cmd "nix-env -iA nixos.git" && nix-env -iA nixos.git && echo )

  # Path to nixos flake and minimal configuration
  local nixos="/mnt/nix/state/etc/nixos" 
  local min="$nixos/configurations/min"

  # Clone git repo into persistant directory
  msg "Cloning nixos git repo"
  if [ -d $nixos ]; then
    run cd $nixos && git pull
  else
    run git clone https://github.com/suderman/nixos $nixos
  fi
  echo

  # Generate config and copy hardware-configuration.nix
  msg "Generating hardware-configuration.nix"
  run nixos-generate-config --root /mnt --dir $min
  run cp -f $min/hardware-configuration.nix $nixos/
  echo

  # If linode install detected, set config.hardware.linode.enable = true;
  if is_linode; then
    msg "Enabling linode in configuration.nix"
    run sed -i 's/hardware\.linode\.enable = false;/hardware.linode.enable = true;/' $min/configuration.nix
    echo
  fi

  # Personal user owns /etc/nixos 
  msg "Updating configuration permissions"
  run chown -R 1000:100 $nixos
  echo
  
  # Run nixos installer
  msg "Installing NixOS in 5 seconds..."
  cmd "nixos-install --flake $nixos\#min --no-root-password"
  sleep 5
  nixos-install --flake $nixos\#min --no-root-password
  echo

  msg "...install is complete. \nReboot without installer media and check if it actually worked. ;-)"
  
}

function is_linode {
  [ "$arg" = "LINODE" ] && return 0 || return 1
}

function is_bios {
  if [ "$arg" = "LINODE" ] || [ "$arg" = "BIOS" ]; then
    return 0
  else 
    return 1
  fi
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
cmd() { printf "$CMD_PROMPT$CMD_COLOR$(echo ${@//\%/%%})$_reset_\n"; }
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
