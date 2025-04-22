{ config, modulesPath, pkgs, ... }: {

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    # (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  config = {

    boot = {
      kernelParams = [ "console=ttyS0" "console=tty1" "boot.shell_on_fail" ];
      kernelPackages = pkgs.linuxPackages_latest;
      initrd.kernelModules = [ "virtio_pci" ];
      loader = {
        grub.enable = true;              # Enable GRUB instead of systemd-boot
        # grub.device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001";
        systemd-boot.enable = false;     # Disable systemd-boot
        efi.canTouchEfiVariables = false; # No UEFI support needed for legacy BIOS boot
      };
    };

    # virtualisation = {
    #   diskSize = 4096;   # Disk size in MB
    #   memorySize = 2048; # RAM in MB
    #   bootLoaderDevice = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001";
    # };

    services.qemuGuest.enable = true;
    services.openssh.enable = true;

  };
}
