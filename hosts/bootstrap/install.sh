#!/usr/bin/env bash

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

# Helper functions
eval "$(cat /etc/nixos/hosts/bootstrap/lib.sh 2>/dev/null || \
        curl -sL https://github.com/suderman/nixos/raw/main/hosts/bootstrap/lib.sh)"

yellow "┏━━━━━━━━━━━━━━━━━━━━━━━┓ \n"
yellow "┃ Jon's NixOS Installer ┃ \n"
yellow "┗━━━━━━━━━━━━━━━━━━━━━━━┛ \n"
echo
blue "Disks & Partitions\n"
blue "━━━━━━━━━━━━━━━━━━━━━━━━━\n"
lsblk -o NAME,FSTYPE,SIZE
blue "━━━━━━━━━━━━━━━━━━━━━━━━━\n"

devices=$(lsblk -o NAME -nir | xargs)
choices=("tmpfs" $devices)
choose -q "1.  Choose the $(yellow ROOT) device" -o choices -m 8 -v "device"
ROOT_MNT="/mnt" ROOT_FS="tmpfs" ROOT_DEV="-"
[ -b /dev/${device} ] && ROOT_FS="ext4" ROOT_DEV="/dev/${device}"

devices=$(echo " $devices" | sed s/"\s${device}"//g | xargs)
choices=("none" $devices)
choose -q "2. Choose the $(yellow BOOT) device" -o choices -m 8 -v "device"
BOOT_MNT="-" BOOT_FS="-" BOOT_DEV="-"
[ -b /dev/${device} ] && BOOT_MNT="/mnt/boot" BOOT_FS="vfat" BOOT_DEV="/dev/${device}"

devices=$(echo " $devices" | sed s/"\s${device}"//g | xargs)
choices=("none" $devices)
choose -q "3. Choose the $(yellow SWAP) device" -o choices -m 8 -v "device"
SWAP_MNT="-" SWAP_FS="-" SWAP_DEV="-"
[ -b /dev/${device} ] && SWAP_FS="swap" SWAP_DEV="/dev/${device}" 

devices=$(echo " $devices" | sed s/"\s${device}"//g | xargs)
choices=("none" $devices)
choose -q "4. Choose the $(yellow NIX) device" -o choices -m 8 -v "device"
NIX_MNT="-" NIX_FS="-" NIX_DEV="-"
[ -b /dev/${device} ] && NIX_MNT="/mnt/nix" NIX_FS="btrfs" NIX_DEV="/dev/${device}" 

# Prepare padded values for table
_A1_____="$(printf "%-9s%s" $ROOT_MNT)" _A2_="$(printf "%-5s%s" $ROOT_FS)" _A3__________="$(printf "%-14s%s" $ROOT_DEV)"
_B1_____="$(printf "%-9s%s" $BOOT_MNT)" _B2_="$(printf "%-5s%s" $BOOT_FS)" _B3__________="$(printf "%-14s%s" $BOOT_DEV)"
_C1_____="$(printf "%-9s%s" $SWAP_MNT)" _C2_="$(printf "%-5s%s" $SWAP_FS)" _C3__________="$(printf "%-14s%s" $SWAP_DEV)"
_D1_____="$(printf "%-9s%s"  $NIX_MNT)" _D2_="$(printf "%-5s%s"  $NIX_FS)" _D3__________="$(printf "%-14s%s"  $NIX_DEV)"

echo
green  "┏━━━━━━┳━━━━━━━━━━━┳━━━━━━━┳━━━━━━━━━━━━━━━━┓ \n"
green  "┃ ROLE ┃ MOUNT     ┃ TYPE  ┃ DEVICE         ┃ \n"
green  "┣━━━━━━╋━━━━━━━━━━━╋━━━━━━━╋━━━━━━━━━━━━━━━━┫ \n"
green  "┃ Root ┃ $_A1_____ ┃ $_A2_ ┃ $_A3__________ ┃ \n"
green  "┃ Boot ┃ $_B1_____ ┃ $_B2_ ┃ $_B3__________ ┃ \n"
green  "┃ Swap ┃ $_C1_____ ┃ $_C2_ ┃ $_C3__________ ┃ \n"
green  "┃ Nix  ┃ $_D1_____ ┃ $_D2_ ┃ $_D3__________ ┃ \n"
green  "┗━━━━━━┻━━━━━━━━━━━┻━━━━━━━┻━━━━━━━━━━━━━━━━┛ \n"
echo

if [ "$NIX_DEV" = "-" ]; then
  msg "Exiting, no NIX device selected"
  exit
fi

if ! ask "Proceed to format and prepare partitions for install?"; then
  exit
fi

# Prepare root mount point
mkdir -p $ROOT_MNT

# If root's device is ext4, first attempt to format it
if [ "$ROOT_FS" = "ext4" ]; then

  if ask "Attempt to format $ROOT_DEV as ext4 for the root partition?"; then
    echo mkfs.ext4 -L root $ROOT_DEV
    mkfs.ext4 -L root $ROOT_DEV
  fi

  # Mount ext4 on /mnt
  echo mount $ROOT_DEV $ROOT_MNT
  mount $ROOT_DEV $ROOT_MNT

# Mount tmpfs at /mnt
elif [ "$ROOT_FS" = "tmpfs" ]; then
  echo mount -t $ROOT_FS none $ROOT_MNT
  mount -t tmpfs none $ROOT_MNT
fi


# Prepare boot mount point
mkdir -p $BOOT_MNT

# Format boot partition
if [ "$BOOT_FS" = "vfat" ]; then

  if ask "Attempt to format $BOOT_DEV as vfat for the boot partition?"; then
    echo mkfs.fat -F32 $BOOT_DEV
    mkfs.fat -F32 $BOOT_DEV
  fi

  echo mount $BOOT_DEV $BOOT_MNT
  mount $BOOT_DEV $BOOT_MNT

fi


# Enable swap partition
if [ "$SWAP_FS" = "swap" ]; then

  echo mkswap $SWAP_DEV
  mkswap $SWAP_DEV

  echo swapon $SWAP_DEV
  swapon $SWAP_DEV

fi


# Prepare nix mount point
mkdir -p $NIX_MNT

# Prepare nix btrfs and subvolumes
if [ "$NIX_FS" = "btrfs" ]; then

  # Format nix partition
  if ask "Attempt to format $NIX_DEV as btrfs for the nix partition?"; then
    echo mkfs.btrfs -L nix $NIX_DEV
    mkfs.btrfs -L nix $NIX_DEV
  fi

  # Mount nix btrfs
  echo mount -o compress-force=zstd,noatime $NIX_DEV $NIX_MNT
  mount -o compress-force=zstd,noatime $NIX_DEV $NIX_MNT

  # Create nested subvolume tree like so:
  # nix
  # ├── snaps
  # └── state
  #     ├── home
  #     ├── etc
  #     └── var
  #         └── log
  echo btrfs subvolume create $NIX_MNT/snaps
  [ -d $NIX_MNT/snaps ] || btrfs subvolume create $NIX_MNT/snaps

  echo btrfs subvolume create $NIX_MNT/state
  [ -d $NIX_MNT/state ] || btrfs subvolume create $NIX_MNT/state

  echo btrfs subvolume create $NIX_MNT/state/home
  [ -d $NIX_MNT/state/home ] || btrfs subvolume create $NIX_MNT/state/home

  echo mkdir -p $NIX_MNT/state/{var,etc/ssh}
  mkdir -p $NIX_MNT/state/{var,etc/ssh}

  echo btrfs subvolume create $NIX_MNT/state/var/log
  [ -d $NIX_MNT/state/var/log ] || btrfs subvolume create $NIX_MNT/state/var/log

fi


exit

# Clone git repo into persistant directory
git clone https://github.com/suderman/nixos /mnt/nix/state/etc/nixos 

# # Generate config and copy hardware-configuration.nix to /mnt/nix/state/etc/nixos/nixos/hosts/sol/hardware-configuration.nix
nixos-generate-config --root /mnt --dir /mnt/nix/state/etc/nixos/hosts/bootstrap
#
# # Run nixos installer
# nixos-install --flake /mnt/nix/state/etc/nixos#bootstrap
