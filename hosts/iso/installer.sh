#!/usr/bin/env bash
set -euo pipefail

# Ensure root
if [[ "$(id -u)" != "0" ]]; then
  echo "Must run this script as root"
  exit 1
fi

# Download flake from github
if [ ! -d "/root/nixos/.git" ]; then
  git clone https://github.com/suderman/nixos "/root/nixos"
  cd /root/nixos
else 
  cd /root/nixos
  git pull
fi

# Remove this eventually
git switch blueprint

# Choose host from flake
host="$(ls -1 hosts/*/ssh_host_ed25519_key.pub | cut -d'/' -f2 | gum choose)"
if [[ -z "$host" ]]; then
  echo "No host selected"
  exit 1
fi

# Get ready
disko --flake .#$host --mode destroy,format,mount --dry-run

# Format disks
header="disko --yes-wipe-all-disks --flake .#$host --mode"
mode="$(echo destroy,format,mount mount SKIP | gum choose --header "$header" --input-delimiter=" ")"
if [[ "$mode" != "SKIP" ]]; then
  disko --yes-wipe-all-disks --flake .#$host --mode $mode
fi

# Persist hostname
mkdir -p /mnt/persist/etc
echo $host > /mnt/persist/etc/hostname

# Offer to receive SSH host key ahead of nixos installation
if gum confirm "Receive SSH host key?" --affirmative="Now" --negative="Later"; then
  mkdir -p /mnt/persist/etc/ssh
  cd /mnt/persist/etc/ssh
  cp -f /root/nixos/hosts/$host/ssh_host_ed25519_key.pub .
  sshed receive
  cd /root/nixos
fi

# Install nixos
if gum confirm "Install NixOS?" --affirmative="Do it" --negative="No way"; then
  nixos-install --flake .#$host --no-root-passwd --root /mnt
  echo
  echo "Power down, remove ISO, and boot up."
fi
