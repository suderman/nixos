#!/usr/bin/env bash
set -euo pipefail

# Download flake from github
if [ ! -d "$HOME/nixos/.git" ]; then
  git clone https://github.com/suderman/nixos "$HOME/nixos"
  cd $HOME/nixos
else 
  cd $HOME/nixos
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

# Install nixos
sudo nixos-install --flake .#$host --no-root-passwd --root /mnt
