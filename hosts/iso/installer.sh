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
sudo disko -m destroy,format,mount -f .#$host

# Persist hostname
mkdir -p /mnt/persist/etc
echo $host > /mnt/persist/etc/hostname

# Install nixos
sudo nixos-install --flake .#$host --no-root-passwd --root /mnt
