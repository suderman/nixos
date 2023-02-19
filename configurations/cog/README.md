# cog

Framework laptop

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

| Label | Size    | Code |
| ----- | ------- | ---- |
| boot  | 512M    | ef00 |
| swap  | 38G     | 8200 |
| nix   | default | 8300 |

```zsh
# Do everything as root
sudo -s

# List devices
lsblk -f

# Format boot partition
mkfs.fat -F32 /dev/nvme0n1p1

# Format swap partition
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2

# Format nix partition
mkfs.btrfs -L nix /dev/nvme0n1p3
```

Mount tmpfs root and create expected directory structure. Mount the paritions we just created.

```zsh
# Mount root as temporary file system on /mnt
mount -t tmpfs -o mode=755 none /mnt

# Prepare mount points
mkdir -p /mnt/{boot,nix}

# Mount boot partition
mount /dev/nvme0n1p1 /mnt/boot
 
# Everything else is mounted on /mnt/nix
mount -o subvol=nix,compress-force=zstd,noatime /dev/nvme0n1p3 /mnt/nix
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
```

Clone git repo into `/mnt/nix/state/etc/nixos` and add generated `hardware-configuration.nix`. Finally, run the nixos installer.

```zsh
# Clone git repo
git clone https://github.com/suderman/nixos /mnt/nix/state/etc/nixos 

# Generate config and copy hardware-configuration.nix to /mnt/nix/state/etc/nixos/nixos/configurations/cog/hardware-configuration.nix
nixos-generate-config --root /mnt

# Run nixos installer
nixos-install --flake /mnt/nix/state/etc/nixos#cog
```
