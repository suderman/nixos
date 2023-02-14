# Handcrafted alternative to hardware-configuration
# Uses linode's device mappings instead of device ids 
{ config, lib, pkgs, modulesPath, ... }: {

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_scsi" "ahci" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # root is ext4
  fileSystems."/" = { 
    fsType = "ext4";
    device = "/dev/sda";
  };

  # swap partition
  swapDevices = [{ device = "/dev/sdb"; }];

  # /nix is btrfs
  fileSystems."/nix" = { 
    fsType = "btrfs";
    device = "/dev/sdc";
    options = [ "compress-force=zstd" "noatime" ]; # btrfs mount options
    neededForBoot = true; 
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted ng
  # (the default) this is the recommended approach. When using systemd-networkds
  # still possible to use this option, but it's recommended to use it in conjunn
  # with explicit per-interface declarations with `networking.interfaces.<inter.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s6.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Enable linode config
  linode.enable = true;

}
