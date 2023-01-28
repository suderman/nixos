#!/bin/sh

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
[ -z "$TMPFS_SIZE" ] && TMPFS_SIZE=1024m
mount -t tmpfs -o size=$TMPFS_SIZE,mode=755 none /mnt

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
  echo $LONGVIEW_KEY > /var/lib/longview/apiKeyFile | sudo tee /var/lib/longview/apiKeyFile
fi

# Add agenix channel
nix-channel --add https://github.com/ryantm/agenix/archive/main.tar.gz agenix
nix-channel --update

# Update installer's configuration to include agenix module and other packages
echo "{ config, pkgs, ... }: { " > /etc/nixos/configuration.nix 
echo "  imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix> <agenix/modules/age.nix> ];" >> /etc/nixos/configuration.nix 
echo "  environment.systemPackages = [ pkgs.git pkgs.magic-wormhole-rs (pkgs.callPackage <agenix/pkgs/agenix.nix> {}) ];" >> /etc/nixos/configuration.nix 
echo "}" >> /etc/nixos/configuration.nix 

# Enable new configuration
nixos-rebuild switch

# Clone git repo into persistant directory
git clone https://github.com/suderman/nixos /mnt/nix/state/etc/nixos 

# # Generate config and copy hardware-configuration.nix to /mnt/nix/state/etc/nixos/nixos/hosts/sol/hardware-configuration.nix
# nixos-generate-config --root /mnt --dir /mnt/nix/state/etc/nixos/scratch
#
# # Run nixos installer
# nixos-install --flake /mnt/nix/state/etc/nixos#sol
