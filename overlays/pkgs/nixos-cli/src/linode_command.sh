declare LINODE_ID

function main {

  # Banner
  yellow "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  yellow "┃         Suderman's Linode Setup           ┃"
  yellow "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

  # Choose linode from list
  [ -z "$LINODE_ID" ] && LINODE_ID="$(choose_linode)"

  # Bail if no ID was selected
  if [ -z "$LINODE_ID" ]; then
    info "Exiting, no LINODE_ID provided"
    return 1
  fi

  # Look up details about this linode
  info "Gathering details..."
  local id="$LINODE_ID" 
  local label="$(linode-cli linodes view $id --format label --no-header --text)"
  local linode_type=$(linode-cli linodes view $id --no-header --text --format type) # example: g6-standard-1
  local linode_size=$(linode-cli linodes type-view $linode_type --no-header --text --format disk) # example: 51200
  local installer_size=1024  # reserve 1GB for installer
  local nixos_size=$((linode_size - installer_size)) # nix uses remaining available disk
  local flags nixos_disk nixos_config installer_disk installer_config

  # Final warning
  warn "DANGER! Last chance to bail!"
  if ! ask --warn "Re-create all disks and configurations for linode $(yellow \"${label}\")?"; then
    return
  fi
  echo

  # Power down
  info "OK! Powering off linode. Please wait..."
  cmd linode-cli linodes shutdown $id
  wait_for_linode "offline"
  echo


  # Delete all configurations
  info "Deleting any existing configurations"
  configs=($(linode-cli linodes configs-list $id --text | awk 'NR > 1 {print $1}'))
  for config_id in "${configs[@]}"; do
    cmd linode-cli linodes config-delete $id $config_id
    sleep 5
  done
  echo

  # Delete all disks
  info "Deleting any existing disks"
  disks=($(linode-cli linodes disks-list $id --text | awk 'NR > 1 {print $1}'))
  for disk_id in "${disks[@]}"; do
    cmd linode-cli linodes disk-delete $id $disk_id
    while [ "$(linode-cli linodes disk-view $id $disk_id --text --no-header --format status 2>/dev/null)" == "deleting" ]; do
      sleep 5
    done
  done
  echo


  # Shared flags
  flags="--text --no-header"

  info "Creating INSTALLER disk"
  cmd linode-cli linodes disk-create $id $flags --label installer --filesystem ext4 --size $installer_size
  disk_id="$(cat /tmp/cmd | awk '{print $1}')"
  installer_disk="--devices.sdb.disk_id $disk_id"
  wait_for_disk $disk_id

  info "Creating NIXOS disk"
  cmd linode-cli linodes disk-create $id $flags --label nixos --filesystem raw --size $nixos_size
  disk_id="$(cat /tmp/cmd | awk '{print $1}')"
  nixos_disk="--devices.sda.disk_id $disk_id"
  wait_for_disk $disk_id


  # Shared flags
  flags="--text --no-header"
  flags="$flags --kernel linode/direct-disk"
  flags="$flags --helpers.updatedb_disabled=0 --helpers.distro=0 --helpers.modules_dep=0 --helpers.network=0 --helpers.devtmpfs_automount=0"
  
  # Create the installer configuration
  info "Creating INSTALLER configuration"
  cmd linode-cli linodes config-create $LINODE_ID $flags $nixos_disk $installer_disk --label installer --kernel linode/direct-disk --root_device /dev/sdb
  installer_config="--config_id $(cat /tmp/cmd | awk '{print $1}')"
  sleep 10
  echo

  # Create the main configuration
  info "Creating NIXOS configuration"
  cmd linode-cli linodes config-create $LINODE_ID $flags $nixos_disk --label nixos --root_device /dev/sda
  nixos_config="--config_id $(cat /tmp/cmd | awk '{print $1}')"
  sleep 10
  echo

  # Rescue mode
  info "Rebooting the linode in RESCUE mode"
  cmd linode-cli linodes rescue $id $installer_disk
  sleep 5
  wait_for_linode "running"
  echo

  # Create INSTALLER disk
  info "Opening a Weblish console:"
  url "https://cloud.linode.com/linodes/$id/lish/weblish"
  echo
  info "Paste the following to download the NixOS installer (copied to clipboard):"
  line1="iso=https://channels.nixos.org/nixos-22.11/latest-nixos-minimal-x86_64-linux.iso"
  line2="curl -L \$iso | tee >(dd of=/dev/sdb) | sha256sum"
  out $line1
  out $line2
  echo "$line1; $line2" | wl-copy
  echo
  info "Wait until it's finished before we reboot with the INSTALLER config"
  pause
  echo

  # Installer config
  info "Rebooting the linode..."
  cmd linode-cli linodes reboot $id $installer_config
  sleep 5
  wait_for_linode "running"
  echo

  info "Opening a Glish console:"
  url "https://cloud.linode.com/linodes/$id/lish/glish"
  echo
  info "Paste the following to install NixOS (second line copied to clipboard):"
  echo "sudo -s"
  echo "bash <(curl -sL https://github.com/suderman/nixos/raw/main/configurations/min/install.sh) LINODE" | tee >(wl-copy)
  echo

  info "Wait until it's finished before we reboot with NIXOS config"
  pause
  echo

  # NixOS config
  info "Rebooting the linode..."
  cmd linode-cli linodes reboot $id $nixos_config
  sleep 5
  wait_for_linode "running"
  echo

  # Update secrets keys
  info "Scanning new host key in 30 seconds..."
  sleep 30
  local ip="$(linode-cli linodes view $id --no-header --text --format ipv4)"
  cmd $dir/secrets/scripts/secrets-keyscan $ip $label --force
  echo
  info "Commit and push to git so changes can be pulled on the new linode at /etc/nixos"
  cmd "cd $dir && git status"
  cd $dir && git status
  sleep 5

  # Test login
  info "Opening a Weblish console:"
  url "https://cloud.linode.com/linodes/$id/lish/weblish"
  echo
  info "Login as user, pull from git, and rebuild config (copied to clipboard):"
  line1="cd /etc/nixos; git pull"
  line2="sudo nixos-rebuild switch"
  cmd "$line1"
  cmd "$line2"
  echo "$line1; $line2" | wl-copy
  echo
  
  # After switching to intended configuration, clean the changes made to min
  # cd /etc/nixos; git restore configurations/min

  # #
  # echo "LINODE_ID:"
  # msg "$LINODE_ID"
  # # # url "$LINODE_ID"
  # url https://suderman.net
  # cmd -d "$LINODE_ID"
  # pwd
  # cmd -d lsblk -f
  # cmd pwd
  # pause
  #
  # if ask "Really do it?"; then
  #   cmt "we are doing it"
  # fi

}


function choose_linode {
  local linodes="$(linode-cli linodes list --text --no-header | awk '{print $1"_"$2}')"
  local linode="$(echo $linodes | tr " " "\n" | fzf \
    --border-label=" Choose which existing linode to prepare " \
    --border \
    --height=40% \
    --margin=1 \
    --padding=1 \
    --layout=reverse \
    --info=hidden)"
  echo "${linode%_*}"
}

function wait_for_linode {
  printf "   "
  while [ "$(linode-cli linodes view $LINODE_ID --text --no-header --format status)" != "$1" ]; do
    echo -n $(yellow ".")
    sleep 5
  done
  echo
}

function wait_for_disk {
  while [ "$(linode-cli linodes disk-view $LINODE_ID $1 --text --no-header --format status 2>/dev/null)" != "ready" ]; do
    sleep 5
  done
  echo
}

main 
