# bootstrap

## Prepare Storage and Configuration Profiles

<https://nixos.org/download.html>

Prepare disks under Storage tab:

| Label  | Type    | Size  | Device   |
| ------ | ------- | ----- | -------- |
| iso    | ext4    | 1536M | /dev/sdd |
| root   | ext4    | 512M  | /dev/sda |
| swap   | swap    | 2048M | /dev/sdb |
| nix    | raw     | -     | /dev/sdc |

Prepare two configurations under Configurations tab:

| Label     | Kernel      | /dev/sda | /dev/sdb | /dev/sdc | /dev/sdd | Root Device |
| --------- | ----------- | -------- | -------- | -------- | -------- | ----------- |
| installer | Direct Disk | root     | swap     | nix      | iso      | /dev/sdd    |
| nixos     | GRUB 2      | root     | swap     | nix      | -        | /dev/sda    |

Disable all Filesystem/Boot Helpers at the bottom.

## Create NixOS installer

Boot node into Rescue Mode with ios mounted at /dev/sda. Then launch a console:

```zsh
# Update SSL certificates to allow HTTPS connections:
update-ca-certificates

# set the iso url to a variable
iso=https://channels.nixos.org/nixos-22.11/latest-nixos-minimal-x86_64-linux.iso

# Download the ISO, write it to the installer disk, and verify the checksum:
curl -L $iso | tee >(dd of=/dev/sda) | sha256sum
```

## Prepare storage devices

After the installer disk is created, boot the node with the installer profile. Then launch a console:

```zsh
# Do everything as root
sudo -s

# Use actual editor
export EDITOR=vim

# List devices
lsblk -f

# When setting up a linode VPS:
# export DEV_SWAP=/dev/sdb 
# export DEV_NIX=/dev/sdc 
# export TMPFS_SIZE=1024m
# export LONGVIEW_KEY=<https://cloud.linode.com/longview>
# curl -L https://github.com/suderman/nixos/raw/main/hosts/bootstrap/init.sh | sh

bash <(curl -sL https://github.com/suderman/nixos/raw/main/hosts/bootstrap/install.sh)
```

## Install NixOS

Finally, run the nixos installer.

```zsh

# Generate config and copy hardware-configuration.nix to /mnt/nix/state/etc/nixos/hosts/bootstrap/hardware-configuration.nix
nixos-generate-config --root /mnt --dir /mnt/nix/state/etc/nixos/hosts/bootstrap

# Run nixos installer
nixos-install --flake /mnt/nix/state/etc/nixos#bootstrap
```
