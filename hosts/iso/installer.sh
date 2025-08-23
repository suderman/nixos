#!/usr/bin/env bash
set -euo pipefail

# Ensure root
if [[ "$(id -u)" != "0" ]]; then
  echo "Must run this script as root"
  exit 1
fi

main() {

  local dir="/root/nixos"
  git_clone https://github.com/suderman/nixos $dir

  # Get hostname (or create new one)
  local hostname
  hostname="$(get_hostname)"
  if [[ -z "$hostname" ]]; then
    echo "No host selected"
    exit 1
  fi

  local hostcfg="$dir/hosts/$hostname/configuration.nix"
  local diskcfg="$dir/hosts/$hostname/disk-configuration.nix"
  local hardcfg="$dir/hosts/$hostname/hardware-configuration.nix"

  # Generate hardware config or use template
  if gum confirm "Detect hardware on this host?" \
    --affirmative="Yes, replace hardware-configuration.nix" \
    --negative="No" --default="No"; then
    nixos detect hardware "$hardcfg"
  fi

  # Optionally include detected disk info in template
  if gum confirm "Detect disks on this host?" \
    --affirmative="Yes, replace disk-configuration.nix" \
    --negative="No" --default="No"; then
    nixos detect disks "$diskcfg"
  fi

  # Edit configuration files in neovim
  if gum confirm "Edit host configuration files?" \
    --affirmative="Yes, make edits" \
    --negative="No" --default="No"; then
    nvim "$diskcfg" "$hostcfg" "$hardcfg" || true
  fi

  # Destroy, format, and mount disks
  set_disks "$diskcfg"

  # Receive ssh host key
  set_hostkey "$hostcfg"

  # Persist hostename and save copy of repo
  echo "$hostname" >/mnt/persist/etc/hostname
  rsync -a --delete "$dir"/ /mnt/persist/etc/nixos/

  # Install nixos
  if gum confirm "Install NixOS?" --affirmative="Do it" --negative="No way"; then
    nixos-install --flake "$dir/#$hostname" --no-root-passwd --root /mnt
    echo
    echo "Power down, remove ISO, and boot up."
  fi

}

# Download flake from github
git_clone() {
  local url="${1-}"
  local dir="${2-}"
  if [ ! -d "$dir/.git" ]; then
    git clone --depth=1 "${url-}" "$dir"
    cd "$dir"
  else
    cd "$dir"
    git pull
  fi
}

# Choose host from flake
get_hostname() {
  # shellcheck disable=SC2012
  ls -1 hosts/*/disk-configuration.nix | cut -d'/' -f2 | gum choose
}

# Select disks to destroy and format
get_disks() {
  nix eval --extra-experimental-features pipe-operators --impure --expr \
    "(import $1 {}).disko.devices.disk |> 
      builtins.mapAttrs (name: disk: name + disk.device) |> 
      builtins.attrValues |> 
      toString" | xargs |
    tr ' ' '\n' |
    sed -E 's|^ssd|0ssd|g' | sort | sed -E 's|^0ssd|ssd|g' |
    sed -E 's|/dev/disk/by-id/| |g' |
    gum choose --no-limit --header "Choose disks to destroy & format:" |
    awk 'BEGIN { printf "[" }
       NF { printf (n++ ? " \"%s\"" : "\"%s\"", $1) }
       END { print "]" }' | cat
}

# Destroy, format, and mount disks
set_disks() {
  local diskcfg="${1}"
  if [[ -e "$diskcfg" ]]; then
    lsblk -o ID-LINK,NAME,FSTYPE,LABEL,SIZE,FSUSE%,MOUNTPOINTS --tree=ID-LINK
    # Destroy & format disks
    disks="$(get_disks "$diskcfg")"
    disko "$diskcfg" -m destroy,format,mount --dry-run &>/dev/null
    if [[ "$disks" != "[]" ]]; then
      disko "$diskcfg" -m destroy --arg disks "$disks"
      disko "$diskcfg" -m format --arg disks "$disks"
    fi
    # Mount disks
    disko "$diskcfg" -m mount
  fi
}

# Offer to receive/import SSH host key ahead of nixos installation
set_hostkey() {
  local hostdir
  hostdir="$(dirname ${1-})"
  local sshdir="/mnt/persist/etc/ssh"
  mkdir -p "$sshdir"
  cp -f "$hostdir/ssh_host_ed25519_key.pub" "$sshdir/ssh_host_ed25519_key.pub"
  if gum confirm "Configure SSH host key?" --affirmative="Now" --negative="Later"; then
    if gum confirm "Receive key from another host or manually type hex?" \
      --affirmative="Receive SSH key" --negative="Import 32-byte hex"; then
      sshed receive "$sshdir"
    else
      sshed import "$sshdir"
    fi
  fi
}

main "${@-}"
