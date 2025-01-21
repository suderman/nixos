# Placeholder
# nixos-generate-config --root /mnt --dir /mnt/nix/state/etc/nixos/configurations/bootstrap
{ config, ... }: { 
  fileSystems."/".device = "/dev/sda";
  boot.loader.grub.device = "/dev/sda";
}
