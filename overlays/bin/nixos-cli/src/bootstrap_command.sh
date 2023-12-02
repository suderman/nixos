local iso="https://channels.nixos.org/nixos-23.11/latest-nixos-minimal-x86_64-linux.iso"
local cli="https://github.com/suderman/nixos/raw/main/overlays/bin/nixos-cli/nixos"
local dir="/etc/nixos" config hardware firmware swap default_swap

function main {

  include git smenu awk:gawk sed:gnused linode-cli jq smenu

  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃              Bootstrap NixOS              ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  if [[ "$(hostname)" == "nixos" ]]; then
    info "Installer ISO detected, launching Stage 1"
    stage1
  elif [[ "$(hostname)" == "bootstrap" ]]; then
    info "Bootstrap configuration detected, launching Stage 2"
    stage2
  else

    info "Choose NixOS configuration to install:"
    config="$(ask "$(configurations)" ${args[--config]})"
    echo

    info "Choose type of hardware:"
    hardware="$(ask "direct linode" ${args[--hardware]})"
    echo

    # Linode install must boot via bios
    if [[ "$hardware" == "linode" ]]; then
      firmware="bios"
      default_swap="min"

    # Direct install on physical hardware
    else 
      info "Choose type of firmware:"
      firmware="$(ask "uefi bios" ${args[--firmware]})"
      default_swap="max"
      echo
    fi

    # Swap partition size
    info "Choose swap size (\"max\" required for hibernate):"
    swap="$(ask "[custom] min max ${args[--swap]}" ${args[--swap]-$default_swap})"
    [[ "$swap" == "[custom]" ]] && swap="$(ask - "2")"
    echo

    info "Review configuration"
    show config: $config
    show hardware: $hardware
    show firmware: $firmware
    show swap: $swap
    echo && pause

    if [[ $hardware == "linode" ]]; then
      info "Starting NixOS installation process on linode server"
      echo && hardware_linode
    else
      info "Starting NixOS installation process on direct hardware"
      echo && hardware_direct
    fi

  fi

}

# Wizard guiding installation directly on hardware (laptop, home server, etc)
function hardware_direct {

  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃ Step 1: Create NixOS installer            ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  echo && info "Create NixOS Installer (choose \"no\" to skip this step)"
  if confirm; then
    echo && info "Choose removable disk to write NixOS installer ISO"
    local disk="$(ask_disk)"
    if [[ -n "${disk}" && -e /dev/$disk ]]; then
      warn "Overwrite all data on ${disk} with NixOS installer?"
      if confirm; then
        info "Unmounting disk"
        for partition in "$(mount | awk '$1 ~ /^\/dev\/'$disk'/ {print $1}')"; do
          task sudo umount $partition
        done
        info "Erasing disk"
        task sudo parted -s /dev/$disk mklabel gpt
        info "Downloading ISO to disk"
        task "sudo bash -c 'curl -L $iso | dd bs=4M status=progress conv=fdatasync of=/dev/${disk}'" 
        info "Finished. Remove NixOS installer disk from this computer."
      fi
    fi
  fi
  echo
  info "Insert NixOS installer disk into target computer. Then boot from the installer."
  pause && echo

  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃ Step 2: Install bootstrap configuration   ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  echo && info "Type the following to install NixOS:"
  local firmware_flag=""; [[ "$firmware" == "uefi" ]] || firmware_flag="-f $firmware"
  local swap_flag=""; [[ "$swap" == "max" ]] || swap_flag="-s $swap"
  line1="sudo -s"
  line2="bash <(curl -sL $cli) bootstrap $firmware_flag $swap_flag"
  show $line1
  show $line2
  echo "$line2" | wl-copy && echo

  info "After it's finished, remove the installer disk and reboot into NixOS."
  pause && echo

  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃ Step 3: Rekey secrets                     ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  echo && info "On the target computer, login as root. Password is also \"root\""
  show "bootstrap login: root"
  echo && info "Run the following command to discover the target's IP address:"
  show "ip -4 a | grep inet"
  echo && info "What is the IP address of the target computer?"
  local ip="$(ask_ip)"
  echo && info "Waiting to keyscan the target..."
  until ping -c1 $ip >/dev/null 2>&1; do sleep 5; done
  task "nixos keyscan $ip $config --add --commit"
  echo && info "Pushing secrets back to git"
  task "cd $dir && git push" 
  sleep 5 && echo

  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃ Step 4: Switch configuration              ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  echo && info "On the target computer, run the following command:"
  show "nixos bootstrap -c $config" && echo
  info "After it's finished, the target computer will automatically reboot into the $config configuration."
  pause && info "Install complete!"

}


# Wizard guiding installation on linode virtual hardware
function hardware_linode {

  if [[ ! -e ~/.config/linode-cli ]]; then
    error "Missing ~/.config/linode-cli configuration. Run linode-cli to login and setup token on this computer, then start again."
  fi

  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃ Step 1: Provision server                  ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  # Choose linode from list
  echo && info "Choose which existing linode to prepare"
  local linode="$(ask "$(linode-cli linodes list --text --no-header | awk '{print $1"_"$2}')")"
  local id="$(echo "${linode%_*}")"
  echo
  [[ -z "$id" ]] && error "Missing linode ID"

  # Look up details about this linode
  info "Gathering details..."; echo
  local label="$(linode-cli linodes view $id --format label --no-header --text)"
  local linode_type=$(linode-cli linodes view $id --no-header --text --format type) # example: g6-standard-1
  local linode_size=$(linode-cli linodes type-view $linode_type --no-header --text --format disk) # example: 51200
  local installer_size=1024  # reserve 1GB for installer
  local nixos_size=$((linode_size - installer_size)) # nix uses remaining available disk
  local flags nixos_disk nixos_config installer_disk installer_config

  # Final warning
  warn "DANGER! Last chance to bail!"
  warn "Re-create all disks and configurations for linode $(magenta \"${label}\")?"
  confirm || return && echo

  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃ Step 2: Create disks & profiles           ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  # Power down
  echo && info "OK! Powering off linode. Please wait..."
  task linode-cli linodes shutdown $id
  wait_for_linode $id "offline" && echo

  # Delete all configurations
  info "Deleting any existing configurations"
  configs=($(linode-cli linodes configs-list $id --text | awk 'NR > 1 {print $1}'))
  for config_id in "${configs[@]}"; do
    task linode-cli linodes config-delete $id $config_id
    sleep 5
  done && echo

  # Delete all disks
  info "Deleting any existing disks"
  disks=($(linode-cli linodes disks-list $id --text | awk 'NR > 1 {print $1}'))
  for disk_id in "${disks[@]}"; do
    task linode-cli linodes disk-delete $id $disk_id
    while [ "$(linode-cli linodes disk-view $id $disk_id --text --no-header --format status 2>/dev/null)" == "deleting" ]; do
      sleep 5
    done
  done && echo

  # Shared flags
  flags="--text --no-header"

  info "Creating INSTALLER disk"
  task linode-cli linodes disk-create $id $flags --label installer --filesystem ext4 --size $installer_size
  disk_id="$(last | awk '{print $1}')"
  installer_disk="--devices.sdb.disk_id $disk_id"
  wait_for_disk $id $disk_id

  info "Creating NIXOS disk"
  task linode-cli linodes disk-create $id $flags --label nixos --filesystem raw --size $nixos_size
  disk_id="$(last | awk '{print $1}')"
  nixos_disk="--devices.sda.disk_id $disk_id"
  wait_for_disk $id $disk_id

  # Shared flags
  flags="--text --no-header"
  flags="$flags --kernel linode/direct-disk"
  flags="$flags --helpers.updatedb_disabled=0 --helpers.distro=0 --helpers.modules_dep=0 --helpers.network=0 --helpers.devtmpfs_automount=0"
  
  # Create the installer configuration
  info "Creating INSTALLER configuration"
  task linode-cli linodes config-create $id $flags $nixos_disk $installer_disk --label installer --kernel linode/direct-disk --root_device /dev/sdb
  installer_config="--config_id $(last | awk '{print $1}')"
  sleep 10 && echo

  # Create the main configuration
  info "Creating NIXOS configuration"
  task linode-cli linodes config-create $id $flags $nixos_disk --label nixos --root_device /dev/sda
  nixos_config="--config_id $(last | awk '{print $1}')"
  sleep 10

  # Rescue mode
  echo && info "Rebooting the linode in RESCUE mode"
  task linode-cli linodes rescue $id $installer_disk
  sleep 5
  wait_for_linode $id "running" && echo

  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃ Step 3: Create NixOS installer            ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  # Create INSTALLER disk
  echo && info "Opening a Weblish console:"
  url "https://cloud.linode.com/linodes/$id/lish/weblish" && echo
  info "Paste the following to download the NixOS installer (copied to clipboard):"
  line1="iso=${iso}"; line2="curl -L \$iso | dd of=/dev/sdb"
  echo $line1
  echo $line2
  echo "$line1; $line2" | wl-copy && echo
  info "Wait until it's finished before we reboot with the INSTALLER config"
  pause
  
  # Installer config
  echo && info "Rebooting the linode..."
  task linode-cli linodes reboot $id $installer_config
  sleep 5
  wait_for_linode $id "running" && echo

  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃ Step 4: Install bootstrap configuration   ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  echo && info "Opening a Glish console:"
  url "https://cloud.linode.com/linodes/$id/lish/glish" && echo
  info "Paste the following to install NixOS (second line copied to clipboard):"
  local swap_flag=""; [[ "$swap" == "min" ]] || swap_flag="-s $swap"
  line1="sudo -s"
  line2="bash <(curl -sL $cli) bootstrap -h linode $swap_flag"
  echo $line1
  echo $line2
  echo "$line2" | wl-copy && echo

  info "Wait until it's finished before we reboot with NIXOS config"
  pause && echo

  # NixOS config
  info "Rebooting the linode..."
  task linode-cli linodes reboot $id $nixos_config
  sleep 5
  wait_for_linode $id "running" && echo

  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃ Step 5: Rekey secrets                     ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  # Wait until live and then keyscan
  local ip="$(ask_ip "$(linode-cli linodes view $id --no-header --text --format ipv4)")"
  echo && info "Waiting to keyscan the linode"
  until ping -c1 $ip >/dev/null 2>&1; do sleep 5; done
  task "nixos keyscan $ip $label --add --commit"
  echo && info "Pushing secrets back to git"
  task "cd $dir && git push" 
  sleep 5 && echo

  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃ Step 6: Switch configuration              ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  # Switch configuration
  echo && info "Opening a Weblish console:"
  url "https://cloud.linode.com/linodes/$id/lish/weblish"
  echo && info "On the linode console, login as root. Password is also \"root\""
  show "bootstrap login: root"
  echo && info "Run the following command (copied to clipboard):"
  line1="nixos bootstrap -c $config"
  echo $line1
  echo "$line1" | wl-copy && echo

  info "After it's finished, the linode will automatically reboot into the $config configuration."
  pause && info "Install complete!"

}

# Stage 1 is run on NixOS installer ISO to install bootstrap configuration
function stage1 {

  if [ "$(id -u)" != "0" ]; then
    warn "Exiting, run as root."
    return 1
  fi

  # Choose a disk to partition
  local disk part bbp esp swap butter
  if is_linode; then disk="sda"
  else
    info "Choose the disk to partition"
    disk="$(ask_disk)"
    [[ "$disk" == nvme* ]] && part="p"
  fi

  # Bail if no disk selected
  if [ ! -e /dev/$disk ]; then
    warn "Exiting, no disk selected"
    return
  fi

  # Final warning
  warn "DANGER! This script will destroy any existing data on the \"$disk\" disk."
  warn "Proceed?"
  confirm || return

  warn "OK! Proceeding in 5 seconds..."
  sleep 5 && echo && echo

  info "Create GPT partition table"
  task parted -s /dev/$disk mklabel gpt
  echo

  # Booting with legacy BIOS requires BBP and ESP partitions
  if is_bios; then

    # /dev/sda1-4
    bbp="${disk}${part}1"
    esp="${disk}${part}2"
    swap="${disk}${part}3"
    butter="${disk}${part}4"

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
    esp="${disk}${part}1"
    swap="${disk}${part}2"
    butter="${disk}${part}3"

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
  # ├── snapshots
  # └── state
  #     ├── home
  #     ├── etc
  #     └── var
  #         └── log
  task mkdir -p /mnt && mount /dev/$butter /mnt
  task btrfs subvolume create /mnt/root
  task btrfs subvolume create /mnt/snapshots
  task btrfs subvolume snapshot -r /mnt/root /mnt/snapshots/root
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

  # Path to nixos flake and bootstrap configuration
  local nixos="/mnt/nix/state/etc/nixos" 
  local bootstrap="$nixos/configurations/bootstrap"

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
  task nixos-generate-config --root /mnt --dir $bootstrap
  task cp -f $bootstrap/hardware-configuration.nix $nixos/
  echo

  # Modify configuration.nix based on detcted linode, uefi, or bios boot
  local cfg="$bootstrap/configuration.nix"
  info "Modifying configuration.nix with detected bootloader"
  task "sed -i '$ d' ${cfg}"
  if is_linode; then
    task "echo '  modules.linode.enable = true;' >> $cfg"
  else
    if is_bios; then
      task "echo '  boot.loader = { grub.device = \"/dev/$disk\"; grub.enable = true; };' >> $cfg"
    else
      task "echo '  boot.loader = { efi.canTouchEfiVariables = true; systemd-boot.enable = true; };' >> $cfg"
    fi
  fi
  task "echo '' >> $cfg"
  task "echo '}' >> $cfg"
  echo

  # Personal user owns /etc/nixos 
  info "Updating configuration permissions"
  task chown -R 1000:100 $nixos
  echo

  # Run nixos installer
  info "Installing NixOS in 5 seconds..."
  show "nixos-install --flake $nixos\#bootstrap --no-root-password"
  sleep 5
  nixos-install --flake $nixos\#bootstrap --no-root-password
  echo

  info "Bootstrap install complete!"
  echo
  info "Reboot without installer media and login as root."
  show "bootstrap login: root"

}


# Stage 2 is run on bootstrap configuration, enables secrets and switches configuration
function stage2 {
  local config="${args[--config]}"
  if has_configuration; then

    echo && info "Pulling secrets"
    task "cd $dir; git pull" && echo

    info "Copying generated hardware-configuration to $config"
    task mv -f $dir/configurations/bootstrap/hardware-configuration.nix $dir/configurations/$config/hardware-configuration.nix
    task "cd $dir; git restore configurations/bootstrap"
    task "chown -R 1000:100 $dir $dir/.git" && echo

    info "Rebuilding system to $config"
    show "nixos-rebuild switch --flake $dir\#${config}"
    nixos-rebuild switch --flake $dir\#${config}

    info "Rebuild complete!"
    info "Reboot in 10 seconds. Login as user and commit the generated hardware-configuration.nix to git."
    sleep 10 && systemctl reboot
    return 0

  else error "Exiting, missing configuration"
  fi
}


# Helper functions
# ----------------

function wait_for_linode {
  printf "  "
  while [ "$(linode-cli linodes view $1 --text --no-header --format status)" != "$2" ]; do
    echo -n $(yellow ".")
    sleep 5
  done && echo
}

function wait_for_disk {
  while [ "$(linode-cli linodes disk-view $1 $2 --text --no-header --format status 2>/dev/null)" != "ready" ]; do
    sleep 5
  done && echo
}

function configurations {
  nix flake show --json $dir | jq -r '.nixosConfigurations | keys[] | select(. != "bootstrap")' | xargs
}

function has_configuration {
  [[ "${args[--config]}" != "" && "${args[--config]}" != "bootstrap" ]] && return 0 || return 1
}

function is_linode {
  [[ "${args[--hardware]}" == "linode" ]] && return 0 || return 1
}

function is_bios {
  [[ "${args[--firmware]}" == "bios" || "${args[--hardware]}" == "linode" ]] && return 0 || return 1
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
