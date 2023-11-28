# Mount btrfs disk to /mnt
mkdir -p /mnt
mount /dev/disk/by-label/nix /mnt

# Delete all of root's subvolumes
btrfs subvolume list -o /mnt/root |
cut -f9 -d' ' |
while read subvolume; do
  btrfs subvolume delete "/mnt/$subvolume"
done

# Delete root itself
btrfs subvolume delete /mnt/root

# Restore root from blank snapshot
btrfs subvolume snapshot /mnt/snapshots/root /mnt/root

# Clean up
umount /mnt
