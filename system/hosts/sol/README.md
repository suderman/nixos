# sol

Linode VPS

## Update secrets/keys.nix

To access encrypted secrets, each host needs an SSH Host key's public key
included in [secrets/keys.nix](https://github.com/suderman/nixos/blob/main/secrets/keys.nix). 
To update a host key, generate a new key from existing host in the network.

```zsh
# Generate private key (this will be transfered to new host later)
ssh-keygen -q -N "" -t ed25519 -f ssh_host_ed25519_key

# Copy public key
cat ssh_host_ed25519_key.pub | wl-copy 
```

Update the line with `sol = "ssh-ed25519 AAA...` using the new public key on the clipboard. 
Then rekey all the secrets, commit and push the git repo.

```zsh
# Rekey the secrets/*.age files to include the new host key
RULES=/etc/nixos/secrets/secrets.nix agenix --rekey

# Commit changes and push repo
cd /etc/nixos && git commit -am "Updated host key" && git push
```

Prepare to transfer private key to host, either via clipboard, USB or [Magic Wormhole](https://search.nixos.org/packages?channel=22.11&show=magic-wormhole-rs&from=0&size=50&sort=relevance&type=packages&query=magic+wormhole).

```zsh
# Create shell with (rust version of) Magic Wormhole available
nix-shell -p magic-wormhole-rs

# Initiate transfer
wormhole-rs send ssh_host_ed25519_key
```

## Prepare Storage and Configuration Profiles

Prepare disks under Storage tab:

| Label  | Type    | Size  | Device   |
| ------ | ------- | ----- | -------- |
| iso    | ext4    | 1024M | /dev/sdd |
| root   | ext4    | 512M  | /dev/sda |
| swap   | swap    | 2048M | /dev/sdb |
| nix    | raw     | -     | /dev/sdc |

Prepare two configuration profiles under Configurations tab:

| Label     | Kernel      | /dev/sda | /dev/sdb | /dev/sdc | /dev/sdd | Root Device |
| --------- | ----------- | -------- | -------- | -------- | -------- | ----------- |
| installer | Direct Disk | root     | swap     | nix      | iso      | /dev/sdd    |
| nixos     | GRUB 2      | root     | swap     | nix      | -        | /dev/sda    |

Disable all Filesystem/Boot Helpers at the bottom of each profile.

## Create NixOS installer

Boot node into Rescue Mode with `iso` mounted at `/dev/sdd`. Then launch a console:

```zsh
# Update SSL certificates to allow HTTPS connections:
update-ca-certificates

# Latest ISO URL found at https://nixos.org/download.html
iso=https://channels.nixos.org/nixos-22.11/latest-nixos-minimal-x86_64-linux.iso

# Download the ISO, write it to the installer disk, and verify the checksum:
curl -L $iso | tee >(dd of=/dev/sdd) | sha256sum
```

## Customize NixOS installer

After the installer disk is created, boot the node with the installer profile. Then launch a console:

```zsh
# Do everything as root
sudo -s

# Use actual editor
export EDITOR=vim

# List devices
lsblk -f

# When setting up a linode VPS:
export DEV_SWAP=/dev/sdb 
export DEV_NIX=/dev/sdc 
export TMPFS_SIZE=1024m
export LONGVIEW_KEY=<https://cloud.linode.com/longview>
curl -L https://github.com/suderman/nixos/raw/main/system/hosts/bootstrap.sh | sh
```

Copy ssh host key (from previous step) into `/mnt/nix/state/etc/ssh/ssh_host_ed25519_key` via clipboard, USB or [Magic Wormhole](https://search.nixos.org/packages?channel=22.11&show=magic-wormhole-rs&from=0&size=50&sort=relevance&type=packages&query=magic+wormhole):

```zsh

# If transfering key via USB or clipboard, create new file with contents:
vi /mnt/nix/state/etc/ssh/ssh_host_ed25519_key

# OR, if transfering key via wormhole, receive the file:
cd /mnt/nix/state/etc/ssh && wormhole-rs receive

# Copy this key to where the installer can use it as well:
cp /mnt/nix/state/etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
```

## Install NixOS

Finally, run the nixos installer.

```zsh

# Generate config and copy hardware-configuration.nix to /mnt/nix/state/etc/nixos/nixos/hosts/sol/hardware-configuration.nix
nixos-generate-config --root /mnt --dir /mnt/nix/state/etc/nixos/scratch

# Run nixos installer
nixos-install --flake /mnt/nix/state/etc/nixos#sol
```
