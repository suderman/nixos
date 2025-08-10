#! /usr/bin/env bash
set -euo pipefail

# Pretty output
gum_warn() { gum style --foreground=196 "✖ Error: $*" && exit 1; }
gum_info() { gum style --foreground=29 "➜ $*"; }
gum_head() { gum style --foreground=99 "$*"; }
gum_show() { gum style --foreground=177 "    $*"; }

# List subdirectories for given directory
dirs() { find "$1" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'; }

# If PRJ_ROOT is set, change to that directory
[[ -n "$PRJ_ROOT" ]] && cd "$PRJ_ROOT"

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------
main() {

  local cmd="${1-}"
  shift

  case "$cmd" in
  add | a)
    nixos_add "$@"
    ;;
  generate | gen | g)
    nixos_generate "$@"
    ;;
  iso | i)
    nixos_iso "$@"
    ;;
  help | *)
    nixos_help
    ;;
  esac

}

# ---------------------------------------------------------------------
# HELP
# ---------------------------------------------------------------------
nixos_help() {
  cat <<EOF
Usage: nixos COMMAND

  deploy    Deploy a NixOS host configuration
  repl      Start the NixOS REPL
  add       Add a NixOS host or user
  generate  Generate missing files
  iso       Manage NixOS ISO image
    path    Show path to NixOS ISO
    build   Build NixOS ISO
    flash   Flash NixOS ISO to a USB device
  help      Show this help
EOF
}

# ---------------------------------------------------------------------
# ADD
# ---------------------------------------------------------------------
nixos_add() {
  add_type=$(gum choose --header="Add to this flake:" "user" "host")
  "nixos_add_${add_type}"
}

nixos_add_user() {
  gum_head "Add a user to this flake:"
  local username
  username="$(gum input --placeholder "username")"

  # Ensure a username was provided
  [[ -z "$username" ]] && gum_warn "Missing username"
  local user="users/${username}"

  # Ensure it doesn't already exist
  if [[ -e "$user" ]]; then
    gum_info "User configuration exists:"
    gum_show "./$user"
  else

    # Create host directory
    mkdir -p "$user"

    # Create an encrypted password.age file (value is x)
    echo "x" |
      age -e -r "$(derive public </tmp/id_age)" \
        >"$user"/password.age

    # Create a basic default.nix in this directory
    {
      echo '{'
      echo '  uid = null;'
      echo '  description = "User";'
      echo '  openssh.authorizedKeys.keyFiles = [./id_ed25519.pub];'
      echo '}'
    } | alejandra -q >"$user/default.nix"

    # Stage in git
    git add "$user" 2>/dev/null || true
    gum_info "User configuration staged: ./$user"
  fi

  # Generate missing files
  nixos_generate
}

nixos_add_host() {
  gum_head "Add a host to this flake:"
  local hostname
  hostname="$(gum input --placeholder "hostname")"

  # Ensure a hostname was provided
  [[ -z "$hostname" ]] && gum_warn "Missing hostname"
  local host="hosts/${hostname}"

  # Ensure it doesn't already exist
  if [[ -e "$host" ]]; then
    gum_info "Host configuration exists:"
    gum_show "./$host"
  else

    # Create host directory
    mkdir -p "$host"/users

    # Add users for home-manager configuration
    for user in $(dirs users); do
      local expr="({ isSystemUser = false; } // (import ./users/$user)).isSystemUser"
      if [[ "$(nix eval --impure --expr "$expr")" == "false" ]]; then
        {
          echo '{ flake, ... }: {'
          echo '  imports = [ flake.homeModules.common ];'
          echo '}'
        } | alejandra -q >"$host/users/$user.nix"
      fi
    done

    # Create a basic configuration.nix in this directory
    {
      echo '{ flake, ... }: {'
      echo '  imports = [ flake.nixosModules.common ];'
      echo '  config.networking.domain = "home";'
      echo '}'
    } | alejandra -q >"$host/configuration.nix"

    # Stage in git
    git add "$host" 2>/dev/null || true
    gum_info "Host configuration staged: ./$host"
  fi

  # Generate missing files
  nixos_generate
}

# ---------------------------------------------------------------------
# GENERATE
# ---------------------------------------------------------------------
nixos_generate() {

  # Generate missing SSH keys for hosts and users
  gum_info "Generating SSH keys..."
  sshed generate

  # Ensure Certificate Authority exists
  if [[ -s zones/ca.crt && -s zones/ca.age ]]; then
    gum_info "Certificate Authority exists..."
    gum_show "./zones/ca.crt"
    gum_show "./zones/ca.age"

  # If it doesn't, generate and add to git
  else
    gum_info "Generating Certificate Authority..."

    # Generate CA key and save to variable
    ca_key=$(mktemp)
    openssl genrsa -out "$ca_key" 4096

    # Generate CA certificate expiring in 70 years
    openssl req -new -x509 -nodes \
      -extensions v3_ca \
      -days 25568 \
      -subj "/CN=Suderman CA" \
      -key "$ca_key" \
      -out zones/ca.crt

    git add zones/ca.crt 2>/dev/null || true
    gum_show "./zones/ca.crt"

    # Encrypt CA key with age identity
    age -e -r "$(derive public </tmp/id_age)" <"$ca_key" \
      >zones/ca.age
    shred -u "$ca_key"

    git add zones/ca.age 2>/dev/null || true
    gum_show "./zones/ca.age"

  fi

  # Ensure secrets are rekeyed for all hosts
  gum_info "Rekeying secrets..."
  agenix rekey -a
}

# ---------------------------------------------------------------------
# ISO
# ---------------------------------------------------------------------
nixos_iso() {

  case "${1:-help}" in
  path | p)
    nixos_iso_path
    ;;
  build | b)
    nixos_iso_build
    ;;
  flash | f)
    nixos_iso_flash
    ;;
  help | *)
    echo test-help
    nixos_help
    ;;
  esac

}

# ---------------------------------------------------------------------
# ISO PATH
# ---------------------------------------------------------------------
nixos_iso_path() {
  shopt -s nullglob
  local files=(result/iso/nixos*.iso)
  shopt -u nullglob
  if [[ ${#files[@]} -gt 0 ]]; then
    readlink -f "${files[0]}"
  else
    echo ""
  fi
}

# ---------------------------------------------------------------------
# ISO BUILD
# ---------------------------------------------------------------------
nixos_iso_build() {
  nix build .#nixosConfigurations.iso.config.system.build.isoImage
}

# ---------------------------------------------------------------------
# ISO FLASH
# ---------------------------------------------------------------------
nixos_iso_flash() {
  local usb_devices usb_selection device
  usb_devices=$(lsblk -dpno NAME,SIZE,MODEL,TRAN | grep -i usb || true)

  # Ensure a USB drive is plugged in
  [[ -z "$usb_devices" ]] && gum_warn "No USB drives detected."

  # Select USB device
  usb_selection=$(echo "$usb_devices" | gum choose --header "Select USB drive to flash the ISO to")
  device="$(awk '{print $1}' <<<"$usb_selection")"

  # Get path to ISO
  local iso_path
  iso_path="$(nixos_iso_path)"
  if [[ -z "$iso_path" ]]; then
    nixos_iso_build
    iso_path="$(nixos_iso_path)"
  fi

  # Final confirmation
  gum_info "You are about to write:"
  gum_show "ISO file: $iso_path"
  gum_show "To device: $device"
  echo
  gum confirm "Are you sure? This will erase all data on $device." || exit 1

  # Run dd
  gum_info "Flashing ISO to $device..."
  gum_show "sudo dd if=\"$iso_path\" of=\"$device\" bs=4M status=progress oflag=sync"
  sudo dd if="$iso_path" of="$device" bs=4M status=progress oflag=sync

  gum_info "Done. ISO flashed to $device."
}

main "${@-}"
