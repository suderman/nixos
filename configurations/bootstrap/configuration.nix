{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
  ];

  # UEFI boot 
  # boot.loader = { efi.canTouchEfiVariables = true; systemd-boot.enable = true; };
  #
  # BIOS boot
  # boot.loader = { grub.device = "/dev/sda"; grub.enable = true; };
  #
  # Linode boot
  # modules.linode.enable = true;

}
