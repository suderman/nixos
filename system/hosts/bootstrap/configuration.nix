{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix 
    ../shared/linode.nix
  ];

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

  system.stateVersion = "22.11";
}
