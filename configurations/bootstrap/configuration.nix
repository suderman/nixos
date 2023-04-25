{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
  ];

  modules.base.enable = true;
  modules.secrets.enable = false;

  # UEFI boot 
  # boot.loader = { efi.canTouchEfiVariables = true; systemd-boot.enable = true; };
  #
  # BIOS boot
  # boot.loader = { grub.device = "/dev/sda"; grub.enable = true; };
  #
  # Linode boot
  # modules.linode.enable = true;

}
