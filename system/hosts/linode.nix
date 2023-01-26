# https://www.linode.com/docs/guides/install-nixos-on-linode/
{ config, lib, pkgs, modulesPath, ... }:

{
  # Standard config from nixos-generate-config
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_scsi" "ahci" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Enable LISH for Linode
  boot.kernelParams = [ "console=ttyS0;19200n8" ];
  boot.loader.grub.extraConfig = ''
    serial --speed=19200 --unit=0 --word=8 --parity=non --stop=1;
    terminal_input serial;
    terminal_output serial
  '';

  # Configure GRUB for Linode
  boot.loader.grub.forceInstall = true;
  boot.loader.grub.device = "nodev";
  boot.loader.timeout = 10;

  # Disable predictable interface names for Linode
  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false; # Disable DHCP globally as we will not need it.
  networking.interfaces.eth0.useDHCP = true;

  # Enable Longview Agent for Linode
  services.longview = {
    enable = true;
    apiKeyFile = "/var/lib/longview/apiKeyFile";
  };

  # Filesystems
  fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
    };

  fileSystems."/nix" =
    { device = "/dev/sdc";
      fsType = "btrfs";
    };

  swapDevices =
    [ { device = "/dev/sdb"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
