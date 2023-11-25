# bootstrap

*Note: this information is outdated and needs some attention from me.*

## Prepare Storage and Configuration Profiles

Prepare disks under the Storage tab:

| Label     | Type    | Size  | Device   |
| --------- | ------- | ----- | -------- |
| installer | ext4    | 1024M | /dev/sdb |
| nixos     | raw     | -     | /dev/sda |


Prepare two configurations under the Configurations tab:

| Label     | Kernel      | /dev/sda | /dev/sdb  | Root Device |
| --------- | ----------- | -------- | --------- | ----------- |
| installer | Direct Disk | nixos    | installer | /dev/sdb    |
| nixos     | Direct Disk | root     | -         | /dev/sda    |

*Disable all Filesystem/Boot Helpers at the bottom!*

## Create NixOS installer

Boot node into Rescue Mode with `installer` mounted at `/dev/sdb`. Then launch a console:

```zsh
# https://nixos.org/download.html
iso=https://channels.nixos.org/nixos-22.11/latest-nixos-minimal-x86_64-linux.iso

# Download the ISO, write it to the installer disk, and verify the checksum:
curl -L $iso | tee >(dd of=/dev/sdb) | sha256sum
```

## Install NixOS

After the installer disk is created, boot the node with the `installer` profile. 
Then launch a console to install NixOS:

```zsh
sudo -s

# Personal computer
bash <(curl -sL https://github.com/buxel/nixos/raw/main/hosts/min/install.sh)

# Linode VPS
bash <(curl -sL https://github.com/buxel/nixos/raw/main/hosts/min/install.sh) LINODE
```
