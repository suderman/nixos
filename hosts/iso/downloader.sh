#!/usr/bin/env bash
set -euo pipefail

# Ensure root
if [[ "$(id -u)" != "0" ]]; then
  echo "Must run this script as root"
  exit 1
fi

# URL to this repo on Github
url="https://github.com/suderman/nixos"

# On first run, clone repo to /etc/nixos
if [ ! -d "/etc/nixos/.git" ]; then
  rm -rf /etc/nixos
  git clone "$url" /etc/nixos
  cd /etc/nixos

# Else git pull for the latest
else
  cd /etc/nixos
  git pull
fi

# Run the installer script in this repo
bash /etc/nixos/hosts/iso/installer.sh
