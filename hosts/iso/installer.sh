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
  cd $dir

  # Get hostname (or create new one)
  local hostname
  hostname="$(get_hostname)"
  if [[ -z "$hostname" ]]; then
    echo "No host selected"
    exit 1
  fi
  local hostdir="$dir/hosts/$hostname"

  # Generate hardware config or use template
  if gum confirm "Detect hardware on this host?" \
    --affirmative="Yes, replace hardware-configuration.nix" \
    --negative="No" --default="No"; then
    nixos detect hardware "$hostdir/hardware-configuration.nix"
  fi

  # Optionally include detected disk info in template
  if gum confirm "Detect disks on this host?" \
    --affirmative="Yes, replace disk-configuration.nix" \
    --negative="No" --default="No"; then
    nixos detect disks "$hostdir/disk-configuration.nix"
  fi

  # Edit configuration files in neovim
  if gum confirm "Edit host configuration files?" \
    --affirmative="Yes, make edits" \
    --negative="No" --default="No"; then
    nvim "$hostdir/disk-configuration.nix" "$hostdir/configuration.nix" "$hostdir/hardware-configuration.nix" || true
  fi

  # Destroy, format, and mount disks
  set_disks "$hostdir"

  # Persist hostname
  set_hostname "$hostname"

  # Receive ssh host key
  set_hostkey "$hostdir"

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

# Detect disks
get_disks() {
  local hostdir="${1-}"
  # Get disko command ready
  disko "$hostdir/disk-configuration.nix" -m destroy,format,mount --dry-run &>/dev/null
  # Detect all disks in this host
  local all_disks
  all_disks="$(nix eval --extra-experimental-features pipe-operators --impure --expr \
    "(import $hostdir/disk-configuration.nix {}).disko.devices.disk |> builtins.attrNames |> toString" | xargs)"
  local selected_disks # Multi-select disks
  # shellcheck disable=SC2086
  selected_disks="$(gum choose --no-limit --header "Choose disks to destroy & format:" $all_disks | xargs)"
  if [[ -n "$selected_disks" ]]; then
    echo "'[\"${selected_disks// /\" \"}\"]'"
  else
    echo "$selected_disks"
  fi
}

# Destroy, format, and mount disks
set_disks() {
  local hostdir="${1-}"
  lsblk -o ID-LINK,NAME,FSTYPE,LABEL,SIZE,FSUSE%,MOUNTPOINTS --tree=ID-LINK
  # Destroy & format disks
  disks="$(get_disks "$hostdir")"
  if [[ -n "$disks" ]]; then
    # shellcheck disable=SC2086
    disko $hostdir/disk-configuration.nix -m destroy --arg disks $disks
    # shellcheck disable=SC2086
    disko $hostdir/disk-configuration.nix -m format --arg disks $disks
  fi
  # Mount disks
  # shellcheck disable=SC2086
  disko $hostdir/disk-configuration.nix -m mount
}

# Persist hostname
set_hostname() {
  local hostname="${1-}"
  mkdir -p /mnt/persist/etc
  echo "$hostname" >/mnt/persist/etc/hostname
}

# Offer to receive SSH host key ahead of nixos installation
set_hostkey() {
  local hostdir="${1-}"
  if gum confirm "Receive SSH host key?" --affirmative="Now" --negative="Later"; then
    mkdir -p /mnt/persist/etc/ssh
    cd /mnt/persist/etc/ssh
    cp -f "$hostdir/ssh_host_ed25519_key.pub" .
    sshed receive
  fi
}

main "${@-}"
