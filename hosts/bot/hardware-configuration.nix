# Provisional for the Dell OptiPlex 5080 Micro until it is installed. Replace with
# sudo nixos-generate-config --no-filesystems --show-hardware-config 2>/dev/null | alejandra -q
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  # Enable DHCP on all interfaces by default
  networking.useDHCP = lib.mkDefault true;

  # Host platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
