{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
  ];

  modules.base.enable = true;
  modules.secrets.enable = false;

  # Configure the SSH daemon
  services.openssh.enable = true;

  # UEFI boot 
  # boot.loader = { efi.canTouchEfiVariables = true; systemd-boot.enable = true; };
  #
  # BIOS boot
  # boot.loader = { grub.device = "/dev/sda"; grub.enable = true; };
  #
  # Linode boot
  # modules.linode.enable = true;

}
