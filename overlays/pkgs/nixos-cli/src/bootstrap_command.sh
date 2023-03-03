# Install script
# sudo -s
# bash <(curl -sL https://github.com/suderman/nixos/raw/main/overlays/pkgs/nixos-cli/nixos) bootstrap
function main {

  if [ "$(id -u)" != "0" ]; then
    warn "Exiting, run as root."
    return 1
  fi

  # Be prepared
  install_dependencies

  # Banner
  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃        Suderman's NixOS Installer         ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  # List disks and partitions for reference
  echo
  blue "Disks & Partitions                           "
  blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  lsblk -o NAME,FSTYPE,SIZE
  blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Choose a disk to partition
  local disk bbp esp swap butter
  is_linode && disk="sda" || disk="$(lsblk -nirdo NAME | pick "Choose the disk to partition for NixOS")"

  # Bail if no disk selected
  if [ ! -e /dev/$disk ]; then
    warn "Exiting, no disk selected"
    return
  fi

  # Final warning
  warn "DANGER! This script will destroy any existing data on the \"$disk\" disk."
  if ! ask --warn "Proceed?"; then
    return
  fi

  warn "OK! Proceeding in 5 seconds..."
  sleep 5 && echo && echo

  info "Create GPT partition table"
  task parted -s /dev/$disk mklabel gpt
  echo

  # Booting with legacy BIOS requires BBP and ESP partitions
  if is_bios; then

    # /dev/sda1-4
    bbp="${disk}1"
    esp="${disk}2"
    swap="${disk}3"
    butter="${disk}4"

    info "Create BIOS boot partition ($bbp)"
    task parted -s /dev/$disk mkpart BBP 1MiB 3MiB
    task parted -s /dev/$disk set 1 bios_grub on
    echo

    info "Create EFI system partition ($esp)"
    task parted -s /dev/$disk mkpart ESP FAT32 3MiB 1GiB
    task parted -s /dev/$disk set 2 esp on
    echo

    info "Create swap partition ($swap)"
    task parted -s /dev/$disk mkpart swap linux-swap 1GiB $(swap_size)GiB
    task parted -s /dev/$disk set 3 swap on
    echo

  # Booting with UEFI, the ESP partition alone is fine
  else

    # /dev/sda1-3
    esp="${disk}1"
    swap="${disk}2"
    butter="${disk}3"

    info "Create EFI system partition ($esp)"
    task parted -s /dev/$disk mkpart ESP FAT32 1MiB 1GiB
    task parted -s /dev/$disk set 1 esp on
    echo

    info "Create swap partition ($swap)"
    task parted -s /dev/$disk mkpart swap linux-swap 1GiB $(swap_size)GiB
    task parted -s /dev/$disk set 2 swap on
    echo

  fi

  info "Create btrfs partition ($butter)"
  task parted -s /dev/$disk mkpart nix btrfs $(swap_size)GiB 100%
  echo

  info "Format EFI system partition"
  task mkfs.fat -F32 -n ESP /dev/$esp
  echo

  info "Enable swap partition"
  task mkswap /dev/$swap
  task swapon /dev/$swap
  echo

  info "Format btrfs partition"
  task mkfs.btrfs -fL nix /dev/$butter
  echo

  info "Create btrfs subvolume structure"
  # nix
  # ├── root
  # ├── snaps
  # └── state
  #     ├── home
  #     ├── etc
  #     └── var
  #         └── log
  task mkdir -p /mnt && mount /dev/$butter /mnt
  task btrfs subvolume create /mnt/root
  task btrfs subvolume create /mnt/snaps
  task btrfs subvolume snapshot -r /mnt/root /mnt/snaps/root
  task btrfs subvolume create /mnt/state
  task btrfs subvolume create /mnt/state/home
  task mkdir -p /mnt/state/{var/lib,etc/{ssh,NetworkManager/system-connections}}
  task btrfs subvolume create /mnt/state/var/log
  task umount /mnt
  echo

  info "Mount root"
  task mount -o subvol=root /dev/$butter /mnt
  echo

  info "Mount nix"
  task "mkdir -p /mnt/nix && mount /dev/$butter /mnt/nix"
  echo

  info "Mount boot"
  task "mkdir -p /mnt/boot && mount /dev/$esp /mnt/boot"
  echo

  # Path to nixos flake and minimal configuration
  local nixos="/mnt/nix/state/etc/nixos" 
  local min="$nixos/configurations/min"

  # Clone git repo into persistant directory
  info "Cloning nixos git repo"
  if [ -d $nixos ]; then
    task "cd $nixos && git pull"
  else
    task "git clone https://github.com/suderman/nixos $nixos"
  fi
  echo

  # Generate config and copy hardware-configuration.nix
  info "Generating hardware-configuration.nix"
  task nixos-generate-config --root /mnt --dir $min
  task cp -f $min/hardware-configuration.nix $nixos/
  echo

  # If linode install detected, set config.hardware.linode.enable = true;
  if is_linode; then
    info "Enabling linode in configuration.nix"
    task "sed -i 's/hardware\.linode\.enable = false;/hardware.linode.enable = true;/' $min/configuration.nix"
    echo
  fi

  # Personal user owns /etc/nixos 
  info "Updating configuration permissions"
  task chown -R 1000:100 $nixos
  echo

  # Run nixos installer
  info "Installing NixOS in 5 seconds..."
  task -d "nixos-install --flake $nixos\#min --no-root-password"
  sleep 5
  nixos-install --flake $nixos\#min --no-root-password
  echo

  info "Install complete!"
  info "Reboot without installer media and check if it actually worked.	(｡◕‿‿◕｡)"

}

function install_dependencies {
  if hasnt git; then
    info "Installing git"
    task nix-env -iA nixos.git
  fi
  if hasnt fzf; then
    info "Installing fzf"
    task nix-env -iA nixos.fzf
  fi
  if hasnt awk; then
    info "Installing awk"
    task nix-env -iA nixos.gawk
  fi
  if hasnt parted; then
    info "Installing parted"
    task nix-env -iA nixos.parted
  fi
}

function is_linode {
  # [ "$ARG" = "LINODE" ] && return 0 || return 1
  [ "${args[type]}" = "linode" ] && return 0 || return 1
}

function is_bios {
  if [ "${args[type]}" = "bios" ] || [ "${args[type]}" = "linode" ]; then
    return 0
  else 
    return 1
  fi
}

# Total memory available in GB
function mem_total {
  free -b | awk '/Mem/ { printf "%.0f\n", $2/1024/1024/1024 + 0.5 }'
}

# Total memory availble squared in GB
function mem_squared {
  mem_total | awk '{printf("%d\n", sqrt($1)+0.5)}'
}

# Memory squared, minimal value 2
function swap_min {
  local mem="$(mem_squared)"
  [ "$mem" -lt "2" ] && mem="2"
  echo $mem
}

# Total memory + memory squared, minimal value 2
function swap_max {
  local mem="$(echo $(mem_total) $(mem_squared) | awk '{printf "%d", $1 + $2}')"
  [ "$mem" -lt "2" ] && mem="2"
  echo $mem
}

# Swap is set to second argument
# - if min, swap is memory squared (at least 2)
# - if max, swap is memory total + memory squared (at least 2)
# - if empty, swap is min if linode, max otherwise
# - if any other value, swap is set to that
function swap_size {
  local swap="${args[--swap]}"
  if [ "$swap" = "min" ]; then
    swap="$(swap_min)"
  elif [ "$swap" = "max" ]; then
    swap="$(swap_max)"
  elif [ "$swap" = "" ]; then
    is_linode && swap="$(swap_min)" || swap="$(swap_max)"
  fi
  # Add 1 since this value will be used in parted and starts at the 1GB position
  echo $swap | awk '{printf "%d", $1 + 1}'
}

main 
