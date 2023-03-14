{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
  ];

  base.enable = true;
  state.enable = true;
  secrets.enable = false;

  # Configure the SSH daemon
  services.openssh.enable = true;

  # UEFI boot 
  # boot.loader = { efi.canTouchEfiVariables = true; systemd-boot.enable = true; };
  #
  # BIOS boot
  # boot.loader = { grub.device = "/dev/sda"; grub.enable = true; };
  #
  # Linode boot
  # hardware.linode.enable = true;

}
