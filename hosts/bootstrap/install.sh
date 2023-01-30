#!/usr/bin/env bash

# Helper functions for install
# https://github.com/the0neWhoKnocks/shell-menu-select
# Scroll to line 288 for real beginning of script
CHAR__GREEN='\033[0;32m'
CHAR__RED='\033[0;31m'
CHAR__RESET='\033[0m'
menuStr=""
returnOrExit=""

function hideCursor {
  printf "\033[?25l"
  
  # capture CTRL+C so cursor can be reset
  trap "showCursor && echo '' && ${returnOrExit} 0" SIGINT
}

function showCursor {
  printf "\033[?25h"
  trap - SIGINT
}

function clearLastMenu {
  local msgLineCount=$(printf "$menuStr" | wc -l)
  # moves the cursor up N lines so the output overwrites it
  echo -en "\033[${msgLineCount}A"

  # clear to end of screen to ensure there's no text left behind from previous input
  [ $1 ] && tput ed
}

function renderMenu {
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
  [ $4 ] && clearLastMenu

  printf "${menuStr}"
}

function renderHelp {
  echo;
  echo "Usage: getChoice [OPTION]..."
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
  echo "  getChoice -q \"What do you feel like eating?\" -o foodOptions -i 6 -m 4 -v \"firstChoice\""
  echo "  printf \"\\n First choice is '\${firstChoice}'\\n\""
  echo;
  echo "  getChoice -q \"Select another option in case the first isn't available\" -o foodOptions"
  echo "  printf \"\\n Second choice is '\${selectedChoice}'\\n\""
  echo;
}

function getChoice {
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
    renderHelp
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
    renderHelp
    $returnOrExit 0
  fi

  set -- "${remainingArgs[@]}"
  local itemsLength=${#menuItems[@]}
  
  # no menu items, at least 1 required
  if [[ $itemsLength -lt 1 ]]; then
    printf "\n ${CHAR__RED}[ERROR] No menu items provided${CHAR__RESET}\n"
    renderHelp
    $returnOrExit 1
  fi

  renderMenu "$instruction" $selectedIndex $maxViewable
  hideCursor

  while $captureInput; do
    read -rsn3 key # `3` captures the escape (\033'), bracket ([), & type (A) characters.

    case "$key" in
      "$KEY__ARROW_UP")
        selectedIndex=$((selectedIndex-1))
        (( $selectedIndex < 0 )) && selectedIndex=$((itemsLength-1))

        renderMenu "$instruction" $selectedIndex $maxViewable true
        ;;

      "$KEY__ARROW_DOWN")
        selectedIndex=$((selectedIndex+1))
        (( $selectedIndex == $itemsLength )) && selectedIndex=0

        renderMenu "$instruction" $selectedIndex $maxViewable true
        ;;

      "$KEY__ENTER")
        clearLastMenu true
        showCursor
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

# Install script
#
# run as root:
# sudo -i
#
# When setting up a laptop or home server:
# export DEV_BOOT=/dev/nvme0n1p1 
# export DEV_SWAP=/dev/nvme0n1p2 
# export DEV_NIX=/dev/nvme0n1p3 
#
# When setting up a linode VPS:
# export DEV_SWAP=/dev/sdb 
# export DEV_NIX=/dev/sdc 
# export LONGVIEW_KEY=01234567-89AB-CDEF-0123456789ABCDEF
#
# curl -L https://github.com/suderman/nixos/blob/main/system/hosts/bootstrap.sh | sh

# devOptions=("none" $(lsblk -o NAME -nir))

lsblk -o NAME,FSTYPE,SIZE

devOptions=("tmpfs" $(lsblk -o NAME -nir))
getChoice -q "1. Choose the ROOT device" -o devOptions -m 8 -v "device"
DEV_ROOT="/dev/${device}"

devOptions=("none" $(lsblk -o NAME -nir))
getChoice -q "2. Choose the BOOT device" -o devOptions -m 8 -v "device"
DEV_BOOT="/dev/${device}"

devOptions=("none" $(lsblk -o NAME -nir))
getChoice -q "3. Choose the SWAP device" -o devOptions -m 8 -v "device"
DEV_SWAP="/dev/${device}"

devOptions=("none" $(lsblk -o NAME -nir))
getChoice -q "4. Choose the NIX device" -o devOptions -m 8 -v "device"
DEV_NIX="/dev/${device}"

echo DEV_ROOT: $DEV_ROOT;
echo DEV_BOOT: $DEV_BOOT;
echo DEV_SWAP: $DEV_SWAP;
echo DEV_NIX: $DEV_NIX;

exit

# DEV_NIX=/dev/nvme0n1p3 or DEV_SWAP=/dev/sdc
if [ ! -z "$DEV_NIX" ]; then

  # Format nix partition
  mkfs.btrfs -L nix $DEV_NIX

# Abort if missing
else
  exit 1
fi


# DEV_BOOT=/dev/nvme0n1p1 
if [ ! -z "$DEV_BOOT" ]; then

  # Format boot partition
  mkfs.fat -F32 $DEV_BOOT

fi


# DEV_SWAP=/dev/nvme0n1p2 or DEV_SWAP=/dev/sdb
if [ ! -z "$DEV_SWAP" ]; then

  # Enable swap partition
  mkswap $DEV_SWAP
  swapon $DEV_SWAP

fi


# Mount root as temporary file system on /mnt
mkdir -p /mnt
# [ -z "$TMPFS_SIZE" ] && TMPFS_SIZE=1024m
# mount -t tmpfs -o size=$TMPFS_SIZE,mode=755 none /mnt
mount -t tmpfs none /mnt

# Prepare mount point
mkdir -p /mnt/nix
 
# Mount btrfs on /mnt/nix
mount -o compress-force=zstd,noatime $DEV_NIX /mnt/nix

# Create nested subvolume tree like so:
# nix
# ├── snaps
# └── state
#     ├── home
#     ├── etc
#     └── var
#         └── log
btrfs subvolume create /mnt/nix/snaps
btrfs subvolume create /mnt/nix/state
btrfs subvolume create /mnt/nix/state/home
mkdir -p /mnt/nix/state/{var,etc/ssh}
btrfs subvolume create /mnt/nix/state/var/log

# Add Longview API key if provided
if [ ! -z "$LONGVIEW_KEY" ]; then
  mkdir -p /mnt/nix/state/var/lib/longview
  echo $LONGVIEW_KEY > /var/lib/longview/apiKeyFile
fi

# Clone git repo into persistant directory
git clone https://github.com/suderman/nixos /mnt/nix/state/etc/nixos 

# # Generate config and copy hardware-configuration.nix to /mnt/nix/state/etc/nixos/nixos/hosts/sol/hardware-configuration.nix
nixos-generate-config --root /mnt --dir /mnt/nix/state/etc/nixos/hosts/bootstrap
#
# # Run nixos installer
# nixos-install --flake /mnt/nix/state/etc/nixos#bootstrap
