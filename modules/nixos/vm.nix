{ config, modulesPath, pkgs, ... }: {

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  config = {

    boot = {
      kernelParams = [ "console=ttyS0" "console=tty1" "boot.shell_on_fail" ];
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = false;
      };
    };

    virtualisation = {
      diskSize = 4096;   # Disk size in MB
      memorySize = 2048; # RAM in MB
    };

    services.openssh.enable = true;

  };
}
