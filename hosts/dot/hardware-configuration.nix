{flake, ...}: {
  imports = [flake.nixosModules.hardware.linode];

  # Linode Direct Disk/fullvirt confirmed with ata_piix storage and e1000 network.
  boot.initrd.availableKernelModules = ["ata_piix" "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod"];
  boot.initrd.systemd.enable = true;
  boot.supportedFilesystems = ["btrfs"];
  nixpkgs.hostPlatform = "x86_64-linux";
}
