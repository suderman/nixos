{flake, ...}: {
  imports = [flake.nixosModules.hardware.linode];

  # Provisional QEMU/virtio hardware. Confirm in the installer before deployment.
  boot.initrd.availableKernelModules = ["ata_piix" "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod"];
  boot.initrd.systemd.enable = true;
  boot.supportedFilesystems = ["btrfs"];
  nixpkgs.hostPlatform = "x86_64-linux";
}
