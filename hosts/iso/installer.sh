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
host="$(ls -1 hosts/*/configuration.nix | cut -d'/' -f2 | grep -v iso | gum choose)"

if [[ -z "$host" ]]; then
  echo "No host selected"
  exit 1
fi

# Format disks
if gum confirm "disko --flake .#$host --mode" --affirmative="destory,format,mount" --negative="mount"; then
  disko --flake .#$host --mode destroy,format,mount
else
  disko --flake .#$host --mode mount
fi

# Persist hostname
mkdir -p /mnt/persist/etc
echo $host > /mnt/persist/etc/hostname

if gum confirm "Receive SSH host key?" --affirmative="Now" --negative="Later"; then
  mkdir -p /mnt/persist/etc/ssh
  cd /mnt/persist/etc/ssh
  sshed-receive
fi

# Install nixos
if gum confirm "Install NixOS?" --affirmative="Do it" --negative="No way"; then
  nixos-install --flake .#$host --no-root-passwd --root /mnt
  echo
  echo "Power down, remove ISO, and boot up."
fi
