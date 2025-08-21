#!/usr/bin/env bash
set -euo pipefail

# Ensure root
if [[ "$(id -u)" != "0" ]]; then
  echo "Must run this script as root"
  exit 1
fi

# Download flake from github
if [ ! -d "/root/nixos/.git" ]; then
  git clone --depth=1 https://github.com/suderman/nixos "/root/nixos"
  cd /root/nixos
else
  cd /root/nixos
  git pull
fi

# Choose host from flake
# shellcheck disable=SC2012
host="$(echo -e "$(ls -1 hosts/*/disk-configuration.nix | cut -d'/' -f2)\n[new]" | gum choose)"
if [[ -z "$host" ]]; then
  echo "No host selected"
  exit 1
elif [[ "$host" == "[new]" ]]; then
  nixos add host
  # shellcheck disable=SC2012
  host="$(ls -1 hosts/*/disk-configuration.nix | cut -d'/' -f2 | gum choose)"
fi

# lsblk -o ID-LINK,NAME,FSTYPE,LABEL,SIZE,FSUSE%,MOUNTPOINTS --tree=ID-LINK | sed 's/^/# /' | cat - packages/nixos/templates/disk-configuration.nix

# Get ready
cfg="hosts/$host/disk-configuration.nix"
disko "$cfg" -m destroy,format,mount --dry-run

# Detect disks
lsblk -o ID-LINK,NAME,FSTYPE,LABEL,SIZE,FSUSE%,MOUNTPOINTS --tree=ID-LINK
all_disks="$(nix eval --extra-experimental-features pipe-operators --impure --expr "(import ./$cfg {}).disko.devices.disk |> builtins.attrNames |> toString" | xargs)"
# shellcheck disable=SC2086
disks="$(gum choose --no-limit --header "Choose disks to destroy & format:" $all_disks | xargs)"

# Destroy & format disks
if [[ -n "$disks" ]]; then
  # shellcheck disable=SC2086,SC2116
  disko $cfg -m destroy --arg disks "$(echo "'[\"${disks// /\" \"}\"]'")"
  # shellcheck disable=SC2086,SC2116
  disko $cfg -m format --arg disks "$(echo "'[\"${disks// /\" \"}\"]'")"
fi

# Mount disks
disko "$cfg" -m mount

# Persist hostname
mkdir -p /mnt/persist/etc
echo "$host" >/mnt/persist/etc/hostname

# Offer to receive SSH host key ahead of nixos installation
if gum confirm "Receive SSH host key?" --affirmative="Now" --negative="Later"; then
  mkdir -p /mnt/persist/etc/ssh
  cd /mnt/persist/etc/ssh
  cp -f "/root/nixos/hosts/$host/ssh_host_ed25519_key.pub" .
  sshed receive
  cd /root/nixos
fi

# Install nixos
if gum confirm "Install NixOS?" --affirmative="Do it" --negative="No way"; then
  nixos-install --flake ".#$host" --no-root-passwd --root /mnt
  echo
  echo "Power down, remove ISO, and boot up."
fi
