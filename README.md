# NixOS

![nixos](https://socialify.git.ci/suderman/nixos/image?description=1&language=1&logo=https%3A%2F%2Fraw.githubusercontent.com%2Fsuderman%2Fnixos%2Fnix.svg&name=1&owner=1&pattern=Charlie%20Brown&theme=Dark)

## Commands 

```
# rebuild the whole system with nixos-rebuild
sudo echo nixos-rebuild switch --flake .#$(hostname)

# rebuild the home directory with home-manager
home-manager switch --extra-experimental-features 'nix-command flakes' --flake .#$(hostname)

# update
nix flake update
```

## Browse config

```
nix repl
:lf .
outputs.nixosConfigurations.<tab>
outputs.homeConfigurations.<tab>
inputs.<tab>
```

```
# Do this as root
sudo -s

# List devices
lsblk -f

# Create partitions
cgdisk /dev/nvme0n1
- ESP: (new), default, 512M, ef00
- Swap: (new), default, 38G, 8200
- Butter: (new), default, default, 8300

# Format boot parition
mkfs.fat -F32 /dev/nvme0n1p1

    1  mount -t tmpfs -o mode=755 none /mnt
    2  mkdir -p /mnt/{boot,nix}
    3  lsblk
    4  lsblk -f
    5  swapon /dev/nvme0n1p2 
    6  mount /dev/nvme0n1p1 /mnt/boot
    7  mount -o subvol=nix,compress-force=zstd,noatime /dev/nvme0n1p3 /mnt/nix
    9  nixos-generate-config --root /mnt
git clone https://github.com/suderman/system /mnt/nix/system
nixos-install --flake /mnt/nix/system#cog


----

# BOOTSTRAP

# Keep keys in /nix/keys dir
sudo -s
mkdir -p /nix/keys

# Generate (or copy) host key to /nix/keys/ssh_host_ed25519_key
ssh-keygen -q -N "" -t ed25519 -f /nix/keys/ssh_host_ed25519_key

# Copy public key to /nix/system/secrets/keys.nix
cat /nix/keys/ssh_host_ed25519_key.pub

# Generate (or copy) user key to /nix/keys/id_ed25519
ssh-keygen -q -N "" -t ed25519 -f /nix/keys/id_ed25519

# Copy public key to /nix/system/secrets/keys.nix
cat /nix/keys/id_ed25519.pub


```
