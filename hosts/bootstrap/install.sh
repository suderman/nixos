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
source <(curl -sL https://github.com/suderman/nixos/raw/main/hosts/bootstrap/lib.sh)

lsblk -o NAME,FSTYPE,SIZE

devices=$(lsblk -o NAME -nir | xargs)
choices=("tmpfs" $devices)
choose -q "1. Choose the ROOT device" -o choices -m 8 -v "device"
[ -b /dev/${device} ] && DEV_ROOT="/dev/${device}" || DEV_ROOT="tmpfs"

devices=$(echo " $devices" | sed s/"\s${device}"//g | xargs)
choices=("none" $devices)
choose -q "2. Choose the BOOT device" -o choices -m 8 -v "device"
[ -b /dev/${device} ] && DEV_BOOT="/dev/${device}" || DEV_BOOT=""

devices=$(echo " $devices" | sed s/"\s${device}"//g | xargs)
choices=("none" $devices)
choose -q "3. Choose the SWAP device" -o choices -m 8 -v "device"
DEV_SWAP="/dev/${device}"

devices=$(echo " $devices" | sed s/"\s${device}"//g | xargs)
choices=("none" $devices)
choose -q "4. Choose the NIX device" -o choices -m 8 -v "device"
DEV_NIX="/dev/${device}"

echo DEV_ROOT: $DEV_ROOT;
echo DEV_BOOT: $DEV_BOOT;
echo DEV_SWAP: $DEV_SWAP;
echo DEV_NIX:  $DEV_NIX;

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
