{ config, pkgs, modulesPath, ... }: {

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  config = {

    boot = {
      kernelParams = [ "console=ttyS0" "console=tty1" "boot.shell_on_fail" ];
      kernelPackages = pkgs.linuxPackages_latest;
      initrd.kernelModules = [ "virtio_pci" ];
      loader = {
        grub.enable = true;               # Enable GRUB instead of systemd-boot
        systemd-boot.enable = false;      # Disable systemd-boot
        efi.canTouchEfiVariables = false; # No UEFI support needed for legacy BIOS boot
      };
    };

    services.qemuGuest.enable = true;
    services.openssh.enable = true;

  };
}
