{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix 
    ../shared/system 
  ];

  # Enable linode config
  linode.enable = true;

  # Configure GRUB
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;

  # Configure the SSH daemon
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };
  services.keyd.enable = true;

  programs.neovim.enable = true;
  programs.mosh.enable = true;

}
