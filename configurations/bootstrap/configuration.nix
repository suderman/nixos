{ config, pkgs, presets, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    # Linode boot
    # presets.linode
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
