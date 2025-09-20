#! /usr/bin/env bash
set -euo pipefail

# Pretty output
gum_exit() { gum style --foreground=196 "✖ $*" && return 1; }
gum_warn() { gum style --foreground=124 "✖ $*"; }
gum_info() { gum style --foreground=29 "➜ $*"; }
gum_head() { gum style --foreground=99 "$*"; }
gum_show() { gum style --foreground=177 "    $*"; }

# List subdirectories for given directory
dirs() { find "$1" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'; }

# If PRJ_ROOT is set, change to that directory
[[ -n "${PRJ_ROOT-}" ]] && cd "$PRJ_ROOT"

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
  detect | t)
    nixos_detect "$@"
    ;;
  iso | i)
    nixos_iso "$@"
    ;;
  sim | s)
    nixos_sim "$@"
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
Usage: nixos [COMMAND]

  deploy            Deploy a NixOS host configuration
  repl              Start the NixOS REPL
  add               Add a NixOS host or user
  generate          Generate missing files
  detect            Detect system devices to generate configuration   
    disks [FILE]    Generate disk-configuration.nix
    hardware [FILE] Generate hardware-configuration.nix
  iso               Manage NixOS ISO image
    path            Show path to NixOS ISO
    build           Build NixOS ISO
    flash           Flash NixOS ISO to a USB device
  sim               Manage NixOS virtual machine
    up [iso]        Run virtual machine (default disk, optional ISO)
    rebuild [boot]  Rebuild virtual machine (default switch, optional boot)
    ssh [iso]       SSH into virtual machine (default disk, optinal ISO)
  help              Show this help
EOF
}

# ---------------------------------------------------------------------
# ADD
# ---------------------------------------------------------------------
nixos_add() {
  local add_type="${1-}"
  if [[ "$add_type" != "user" && "$add_type" != "host" ]]; then
    add_type=$(gum choose --header="Add to this flake:" "user" "host")
  fi
  "nixos_add_${add_type}"
}

nixos_add_user() {

  # Ensure access to age identity
  agenix unlock quiet

  gum_head "Add a user to this flake:"
  local username
  username="$(gum input --placeholder "username")"

  # Ensure a username was provided
  [[ -z "$username" ]] && gum_exit "Missing username"
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
    alejandra -q <"${templates-}"/user.nix >"$user/default.nix"

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
  [[ -z "$hostname" ]] && gum_exit "Missing hostname"
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
        alejandra -q <"${templates-}"/home.nix >"$host/users/$user.nix"
      fi
    done

    # Create a basic configuration files in this directory
    alejandra -q <"${templates-}"/configuration.nix >"$host/configuration.nix"
    alejandra -q <"${templates-}"/hardware-configuration.nix >"$host/hardware-configuration.nix"
    alejandra -q <"${templates-}"/disk-configuration.nix >"$host/disk-configuration.nix"

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

  # Ensure access to age identity
  agenix unlock quiet

  # Generate missing SSH keys for hosts and users
  gum_info "Generating SSH keys..."
  for host in $(dirs hosts | grep -v iso); do
    agenix hex |
      derive hex "$host" |
      derive ssh |
      derive public "$host@${derivation_path-}" \
        >"hosts/$host/ssh_host_ed25519_key.pub"
    git add "hosts/$host/ssh_host_ed25519_key.pub" 2>/dev/null || true
    gum_show "./hosts/$host/ssh_host_ed25519_key.pub"
  done
  for user in $(dirs users); do
    agenix hex |
      derive hex "$user" |
      derive ssh |
      derive public "$user@${derivation_path-}" \
        >"users/$user/id_ed25519.pub"
    git add "users/$user/id_ed25519.pub" 2>/dev/null || true
    gum_show "./users/$user/id_ed25519.pub"
  done

  # Generate missing age identities for each user
  gum_info "Generating age identities..."
  for user in $(dirs users); do
    agenix hex |
      derive hex "$user" |
      derive age |
      derive public \
        >"users/$user/id_age.pub"
    git add "users/$user/id_age.pub" 2>/dev/null || true
    gum_show "./users/$user/id_age.pub"
  done

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
# DETECT
# ---------------------------------------------------------------------
nixos_detect() {

  case "${1:-help}" in
  disks | d)
    nixos_detect_disks "${2:-}"
    ;;
  hardware | h)
    nixos_detect_hardware "${2:-}"
    ;;
  help | *)
    nixos_help
    ;;
  esac

}

# ---------------------------------------------------------------------
# DETECT DISKS
# ---------------------------------------------------------------------
nixos_detect_disks() {
  local file="${1-}"
  local out
  out="$(lsblk -o ID-LINK,NAME,FSTYPE,LABEL,SIZE,FSUSE%,MOUNTPOINTS --tree=ID-LINK |
    sed 's/^/# /' | cat - "${templates-}"/disk-configuration.nix | alejandra -q)"
  [[ -n "$file" ]] && echo "$out" >"$file"
  bat --file-name "disk-configuration.nix" <<<"$out"
  nc -N x0.at 9999 <<<"$out" || true
}

# ---------------------------------------------------------------------
# DETECT HARDWARE
# ---------------------------------------------------------------------
nixos_detect_hardware() {
  local file="${1-}"
  local out
  out="$(sudo nixos-generate-config --no-filesystems --show-hardware-config 2>/dev/null |
    alejandra -q)"
  [[ -n "$file" ]] && echo "$out" >"$file"
  bat --file-name "hardware-configuration.nix" <<<"$out"
  nc -N x0.at 9999 <<<"$out" || true
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
  gum_show "nix build .#nixosConfigurations.iso.config.system.build.isoImage"
  nix build .#nixosConfigurations.iso.config.system.build.isoImage
}

# ---------------------------------------------------------------------
# ISO FLASH
# ---------------------------------------------------------------------
nixos_iso_flash() {
  local usb_devices usb_selection device
  usb_devices=$(lsblk -dpno NAME,SIZE,MODEL,TRAN | grep -i usb || true)

  # Ensure a USB drive is plugged in
  [[ -z "$usb_devices" ]] && gum_exit "No USB drives detected."

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

# ---------------------------------------------------------------------
# SIM
# ---------------------------------------------------------------------
nixos_sim() {

  # Derive ssh private key
  agenix hex |
    derive hex sim |
    derive ssh >hosts/sim/ssh_host_ed25519_key &&
    chmod 600 hosts/sim/ssh_host_ed25519_key

  # Set path to ssh private key in env variable
  export NIX_SSHOPTS="-p 2222 -i hosts/sim/ssh_host_ed25519_key"

  [[ -e hosts/sim/disk1.img ]] || nix run nixpkgs#qemu-img create -f qcow2 hosts/sim/disk1.img 100G
  [[ -e hosts/sim/disk2.img ]] || nix run nixpkgs#qemu-img create -f qcow2 hosts/sim/disk2.img 100G
  [[ -e hosts/sim/disk3.img ]] || nix run nixpkgs#qemu-img create -f qcow2 hosts/sim/disk3.img 100G
  [[ -e hosts/sim/disk4.img ]] || nix run nixpkgs#qemu-img create -f qcow2 hosts/sim/disk4.img 100G

  echo iiiiiii
  case "${1:-help}" in
  up | u)
    nixos_sim_up "${2:-disk}"
    ;;
  rebuild | r)
    nixos_sim_rebuild "${2:-switch}"
    ;;
  ssh | s)
    nixos_sim_ssh "${2:-disk}"
    ;;
  help | *)
    nixos_help
    ;;
  esac

}

# ---------------------------------------------------------------------
# SIM UP
# ---------------------------------------------------------------------
nixos_sim_up() {

  local boot=()
  [[ "$1" == "iso" ]] && boot=(-boot d -cdrom "$(nixos iso path)")

  nix run nixpkgs#qemu -- \
    -enable-kvm \
    -m 6144 \
    -cpu host \
    -smp 4 \
    -device virtio-vga-gl \
    -display gtk,gl=on \
    -device ich9-intel-hda,id=snd0 -device hda-output \
    -device virtio-tablet-pci \
    -nic user,hostfwd=tcp::2222-:22,hostfwd=tcp::12345-:12345,hostfwd=tcp::4443-:443 \
    -device virtio-blk-pci,drive=disk1,serial=1 \
    -drive file=hosts/sim/disk1.img,format=qcow2,if=none,id=disk1 \
    -device virtio-blk-pci,drive=disk2,serial=2 \
    -drive file=hosts/sim/disk2.img,format=qcow2,if=none,id=disk2 \
    -device virtio-blk-pci,drive=disk3,serial=3 \
    -drive file=hosts/sim/disk3.img,format=qcow2,if=none,id=disk3 \
    -device virtio-blk-pci,drive=disk4,serial=4 \
    -drive file=hosts/sim/disk4.img,format=qcow2,if=none,id=disk4 \
    "${boot[@]}"

}

# ---------------------------------------------------------------------
# SIM REBUILD
# ---------------------------------------------------------------------
nixos_sim_rebuild() {

  if [[ "${1-switch}" == "boot" ]]; then
    gum_show "nixos-rebuild --target-host root@localhost --flake .#sim boot"
    nixos-rebuild --target-host root@localhost --flake .#sim boot
  else
    gum_show "nixos-rebuild --target-host root@localhost --flake .#sim switch"
    nixos-rebuild --target-host root@localhost --flake .#sim switch
  fi

}

# ---------------------------------------------------------------------
# SIM SSH
# ---------------------------------------------------------------------
nixos_sim_ssh() {

  if [[ "${1-disk}" == "iso" ]]; then
    gum_show "passh -p x ssh $NIX_SSHOPTS root@localhost"
    # shellcheck disable=SC2086
    passh -p x ssh $NIX_SSHOPTS root@localhost
  else
    gum_show "ssh $NIX_SSHOPTS root@localhost"
    # shellcheck disable=SC2086
    ssh $NIX_SSHOPTS root@localhost
  fi

}

main "${@-}"
