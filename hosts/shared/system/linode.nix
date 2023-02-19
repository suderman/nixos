# Handcrafted alternative to hardware-configuration
# Uses linode's device mappings instead of device ids 
# https://www.linode.com/docs/guides/install-nixos-on-linode/
{ config, lib, pkgs, modulesPath, ... }: with lib;

let 
  cfg = config.hardware.linode;
  qemu = import (modulesPath + "/profiles/qemu-guest.nix") { inherit config lib; };

in {
  options = {
    hardware.linode.enable = options.mkEnableOption "linode"; 
  };

  # hardware.linode.enable = true;
  config = mkIf cfg.enable (recursiveUpdate qemu {

    # Enable LISH for Linode
    boot.initrd.availableKernelModules = [ "ahci" "sd_mod" ];
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

    # IPv6 is broken when trying to reach CloudFlare DNS
    networking.enableIPv6 = false;

    # Install Diagnostic Tools
    environment.systemPackages = with pkgs; [
      inetutils
      mtr
      sysstat
    ];

    nixpkgs.hostPlatform = mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;

    # root is ext4
    fileSystems."/" = { 
      fsType = "ext4";
      device = "/dev/sda";
    };

    # swap partition
    swapDevices = [{ 
      device = "/dev/sdb"; 
    }];

    # /nix is btrfs
    fileSystems."/nix" = { 
      fsType = "btrfs";
      device = "/dev/sdc";
      options = [ "compress-force=zstd" "noatime" ]; # btrfs mount options
      neededForBoot = true; 
    };

  });

}
