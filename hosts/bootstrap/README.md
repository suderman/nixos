# bootstrap

## Prepare Storage and Configuration Profiles

<https://nixos.org/download.html>

Prepare disks under Storage tab:

| Label  | Type    | Size  | Device   |
| ------ | ------- | ----- | -------- |
| root   | ext4    | 1024M | /dev/sda |
| iso    | ext4    | 1024M | /dev/sdb |
| swap   | swap    | 2048M | /dev/sdc |
| nix    | raw     | -     | /dev/sdd |


Prepare two configurations under Configurations tab:

| Label     | Kernel      | /dev/sda | /dev/sdb | /dev/sdc | /dev/sdd | Root Device |
| --------- | ----------- | -------- | -------- | -------- | -------- | ----------- |
| installer | Direct Disk | root     | iso      | swap     | nix      | /dev/sdb    |
| nixos     | GRUB 2      | root     | -        | swap     | nix      | /dev/sda    |

Disable all Filesystem/Boot Helpers at the bottom.

## Create NixOS installer

Boot node into Rescue Mode with iso mounted at /dev/sdb. Then launch a console:

```zsh
# Update SSL certificates to allow HTTPS connections:
update-ca-certificates

# set the iso url to a variable
iso=https://channels.nixos.org/nixos-22.11/latest-nixos-minimal-x86_64-linux.iso

# Download the ISO, write it to the installer disk, and verify the checksum:
curl -L $iso | tee >(dd of=/dev/sdb) | sha256sum
```

## Install NixOS

After the installer disk is created, boot the node with the installer profile. Then launch a console:

```zsh
sudo bash <(curl -sL https://github.com/suderman/nixos/raw/main/hosts/bootstrap/install.sh)
```
