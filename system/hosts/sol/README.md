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

Update the line with `cog = "ssh-ed25519 AAA...` using the new public key on the clipboard. 
Then rekey all the secrets, commit and push the git repo.

```zsh
# Rekey the secrets/*.age files to include the new host key
RULES=/etc/nixos/secrets/secrets.nix agenix --rekey

# Commit changes and push repo
cd /etc/nixos && git commit -am "Updated host key" && git push
```

Prepare to transfer private key to host, either via USB or [Magic Wormhole](https://search.nixos.org/packages?channel=22.11&show=magic-wormhole-rs&from=0&size=50&sort=relevance&type=packages&query=magic+wormhole).

```zsh
# Create shell with (rust version of) Magic Wormhole available
nix-shell -p magic-wormhole-rs

# Initiate transfer
wormhole-rs send ssh_host_ed25519_key
```

## Boot NixOS installer

<https://nixos.org/download.html>

Prepare internal drive (using GParted or `cgdisk /dev/nvme0n1`) and make 3 partitions:

Prepare disks under Storage tab:

installer	ext4	1024 MB	2023-01-23 19:45	
boot	ext4	512 MB	2023-01-25 21:51	
swap	swap	2048 MB	2023-01-25 21:53	
nix	raw	47616 MB

| Label     | Type    | Size  |
| --------- | ------- | ----- |
| installer | ext4    | 1024M |
| boot      | ext4    | 512M |
| swap      | swap    | 2048Mcd  |
| nix       | default | 8300 |

```zsh
# Do everything as root
sudo -s

# Use actual editor
export EDITOR=vim

# List devices
lsblk -f

# Enable swap partition
swapon /dev/sdb

# Format nix partition
mkfs.btrfs -L nix /dev/sdc
```

Mount tmpfs root and create expected directory structure. Mount the paritions we just created.

```zsh
# Mount root as temporary file system on /mnt
mount -t tmpfs -o size=1024m,mode=755 none /mnt

# Prepare mount point
mkdir -p /mnt/nix
 
# Mount btrfs on /mnt/nix
mount -o compress-force=zstd,noatime /dev/sdc /mnt/nix
```

Create nested subvolumes in /mnt/nix to manage state.

```zsh
# Create nested subvolume tree like so:
# nix
# ├── snaps
# └── state
#     ├── home
#     ├── etc
#     └── var
#         └── log
btrfs subvolume create /mnt/nix/snaps
btrfs subvolume create /mnt/nix/state
btrfs subvolume create /mnt/nix/state/home
mkdir -p /mnt/nix/state/{var,etc/ssh}
btrfs subvolume create /mnt/nix/state/var/log
```
Copy ssh host key (from previous step) into `/mnt/nix/state/etc/ssh/ssh_host_ed25519_key` via USB or [Magic Wormhole](https://search.nixos.org/packages?channel=22.11&show=magic-wormhole-rs&from=0&size=50&sort=relevance&type=packages&query=magic+wormhole):

```zsh
# Create shell with (rust version of) Magic Wormhole available
nix-shell -p magic-wormhole-rs

# Complete transfer
cd /mnt/nix/state/etc/ssh && wormhole-rs receive

mkdir -p /nix/state/etc/ssh && cp /mnt/nix/state/etc/ssh/ssh_host_ed25519_key /nix/state/etc/ssh
```

Install dependencies.

```zsh

# Add agenix module /etc/nixos/configuration.nix
vi /etc/nixos/configuration.nix

# Replace imports with:
# imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix> <agenix/modules/age.nix> ];

# Add change and update
nix-channel --add https://github.com/ryantm/agenix/archive/main.tar.gz agenix
nix-channel --update

#mkdir -p /mnt/nix/tmp
#mount --bind /mnt/nix/tmp /tmp

nixos-rebuild switch

# Install agenix CLI and git
nix-env -iA agenix.agenix nixos.git
```

Clone git repo into `/mnt/nix/state/etc/nixos` and add generated `hardware-configuration.nix`. Finally, run the nixos installer.

```zsh

# Clone git repo
git clone https://github.com/suderman/nixos /mnt/nix/state/etc/nixos 

# Generate config and copy hardware-configuration.nix to /mnt/nix/state/etc/nixos/nixos/hosts/sol/hardware-configuration.nix
nixos-generate-config --root /mnt --dir /mnt/nix/state/etc/nixos/scratch

# Run nixos installer
nixos-install --flake /mnt/nix/state/etc/nixos#sol
```
