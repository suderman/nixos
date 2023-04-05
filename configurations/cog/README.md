# cog

Framework laptop

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
# ├── root
# ├── snapshots
# └── state
#     ├── home
#     ├── etc
#     └── var
#         └── log
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/nix/snapshots
btrfs subvolume create /mnt/nix/state
btrfs subvolume create /mnt/nix/state/home
mkdir -p /mnt/nix/state/{var,etc/ssh}
btrfs subvolume create /mnt/nix/state/var/log
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
